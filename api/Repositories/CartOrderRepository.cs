using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IWishlistRepository
{
    Task<List<WishlistItemDto>> GetWishlistAsync(int userId);
    Task<bool> ToggleWishlistAsync(int userId, int productId);
}

public interface ICartRepository
{
    Task<CartDto> GetCartAsync(int userId);
    Task<int> AddToCartAsync(int userId, AddToCartRequest req);
    Task<string> UpdateCartAsync(int cartId, int userId, int quantity);
    Task DeleteCartItemAsync(int cartId, int userId);
}

public interface IOrderRepository
{
    Task<int> PlaceOrderAsync(int userId, int addressId, string paymentMethod, string? couponCode = null);
    Task<List<OrderListItemDto>> GetOrdersAsync(int userId);
    Task<OrderDetailDto?> GetOrderDetailAsync(int orderId, int userId);
    Task<OrderDetailDto?> CancelOrderByBuyerAsync(int orderId, int userId, string cancellationReason);
}

public interface IAddressRepository
{
    Task<List<AddressDto>> GetAddressesAsync(int userId);
    Task<int> AddAddressAsync(int userId, AddAddressRequest req);
    Task SetDefaultAddressAsync(int addressId, int userId);
}

// ---- Implementations ----

public class WishlistRepository(IConfiguration config) : IWishlistRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<List<WishlistItemDto>> GetWishlistAsync(int userId)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<WishlistRow>(
            "usp_Commerce_Wishlist_GetByUser",
            new { UserId = userId, PageNumber = 1, PageSize = 100 },
            commandType: System.Data.CommandType.StoredProcedure);

        return rows.Select(r => new WishlistItemDto
        {
            ProductId    = r.ProductId,
            Name         = r.ProductName,
            MRP          = r.MRP,
            SellingPrice = r.SellingPrice,
            DiscountPct  = r.MRP > 0 ? Math.Round((r.MRP - r.SellingPrice) * 100m / r.MRP, 1) : 0,
            BrandName    = r.BrandName,
            PrimaryImage = r.PrimaryImageUrl,
            CreatedAt    = r.AddedAt
        }).ToList();
    }

    public async Task<bool> ToggleWishlistAsync(int userId, int productId)
    {
        using var db = Conn();

        var exists = await db.QuerySingleOrDefaultAsync<int?>(
            "SELECT TOP 1 WishlistId FROM Wishlist WHERE UserId = @UserId AND ProductId = @ProductId AND IsDeleted = 0",
            new { UserId = userId, ProductId = productId },
            commandType: System.Data.CommandType.Text);

        if (exists.HasValue)
        {
            await db.ExecuteAsync(
                "usp_Commerce_Wishlist_Remove",
                new { UserId = userId, ProductId = productId },
                commandType: System.Data.CommandType.StoredProcedure);
            return false;
        }
        else
        {
            await db.ExecuteAsync(
                "usp_Commerce_Wishlist_Add",
                new { UserId = userId, ProductId = productId },
                commandType: System.Data.CommandType.StoredProcedure);
            return true;
        }
    }

    private sealed class WishlistRow
    {
        public int      WishlistId   { get; set; }
        public DateTime AddedAt      { get; set; }
        public int      ProductId    { get; set; }
        public string   ProductName  { get; set; } = string.Empty;
        public decimal  MRP          { get; set; }
        public decimal  SellingPrice { get; set; }
        public string?  BrandName    { get; set; }
        public string?  PrimaryImageUrl { get; set; }
    }
}

public class CartRepository(IConfiguration config) : ICartRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<CartDto> GetCartAsync(int userId)
    {
        using var db = Conn();

        var rows = (await db.QueryAsync<CartRow>(
            "usp_Commerce_Cart_GetByUser",
            new { UserId = userId, SavedForLater = false },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();

        var items = rows.Select(r =>
        {
            decimal discountPct = r.MRP > 0 ? Math.Round((r.MRP - r.SellingPrice) * 100m / r.MRP, 1) : 0;
            return new CartItemDto
            {
                CartId       = r.CartId,
                ProductId    = r.ProductId,
                ProductName  = r.ProductName,
                BrandName    = r.BrandName,
                PrimaryImage = r.PrimaryImageUrl,
                SizeLabel    = r.Size,
                ColorName    = r.Color,
                Quantity     = r.Quantity,
                MRP          = r.MRP,
                SellingPrice = r.FinalPrice,
                DiscountPct  = discountPct,
                ItemMRP      = r.MRP * r.Quantity,
                ItemTotal    = r.LineTotal
            };
        }).ToList();

        decimal totalMRP      = items.Sum(i => i.ItemMRP);
        decimal totalFinal    = items.Sum(i => i.ItemTotal);
        decimal totalDiscount = totalMRP - totalFinal;
        decimal delivery      = totalFinal >= 499 ? 0 : (items.Count > 0 ? 49 : 0);

        var summary = new CartSummaryDto
        {
            TotalMRP       = totalMRP,
            TotalDiscount  = totalDiscount,
            DeliveryCharge = delivery,
            FinalAmount    = totalFinal + delivery
        };

        return new CartDto { Items = items, Summary = summary };
    }

    public async Task<int> AddToCartAsync(int userId, AddToCartRequest req)
    {
        using var db = Conn();

        // Resolve VariantId from size/color labels
        var variantId = await db.QuerySingleOrDefaultAsync<int?>(
            @"SELECT TOP 1 VariantId FROM ProductVariants
              WHERE ProductId = @ProductId
                AND IsDeleted = 0 AND IsActive = 1
                AND (@Size IS NULL OR Size = @Size)
                AND (@Color IS NULL OR Color = @Color)
              ORDER BY VariantId",
            new
            {
                req.ProductId,
                Size  = string.IsNullOrWhiteSpace(req.SizeLabel)  ? null : req.SizeLabel,
                Color = string.IsNullOrWhiteSpace(req.ColorName) ? null : req.ColorName
            },
            commandType: System.Data.CommandType.Text);

        if (variantId is null)
        {
            // Fallback: pick first available variant
            variantId = await db.QuerySingleOrDefaultAsync<int?>(
                "SELECT TOP 1 VariantId FROM ProductVariants WHERE ProductId = @ProductId AND IsDeleted = 0 AND IsActive = 1 ORDER BY VariantId",
                new { req.ProductId },
                commandType: System.Data.CommandType.Text);
        }

        if (variantId is null)
            throw new InvalidOperationException("No available variant found for this product.");

        var rows = (await db.QueryAsync<CartRow>(
            "usp_Commerce_Cart_AddItem",
            new { UserId = userId, req.ProductId, VariantId = variantId, Quantity = req.Quantity },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();

        return rows.FirstOrDefault()?.CartId ?? 0;
    }

    public async Task<string> UpdateCartAsync(int cartId, int userId, int quantity)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Commerce_Cart_UpdateQuantity",
            new { CartId = cartId, UserId = userId, Quantity = quantity },
            commandType: System.Data.CommandType.StoredProcedure);
        return "updated";
    }

    public async Task DeleteCartItemAsync(int cartId, int userId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Commerce_Cart_RemoveItem",
            new { CartId = cartId, UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private sealed class CartRow
    {
        public int      CartId         { get; set; }
        public int      ProductId      { get; set; }
        public string   ProductName    { get; set; } = string.Empty;
        public string?  BrandName      { get; set; }
        public string?  PrimaryImageUrl { get; set; }
        public string?  Size           { get; set; }
        public string?  Color          { get; set; }
        public int      Quantity       { get; set; }
        public decimal  MRP            { get; set; }
        public decimal  SellingPrice   { get; set; }
        public decimal  FinalPrice     { get; set; }
        public decimal  LineTotal      { get; set; }
    }
}

public class OrderRepository(IConfiguration config) : IOrderRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<int> PlaceOrderAsync(int userId, int addressId, string paymentMethod, string? couponCode = null)
    {
        using var db = Conn();

        byte paymentMode = paymentMethod?.ToLower() switch
        {
            "cod" or "cash_on_delivery" => 1,
            "online" or "card" or "upi" => 2,
            "wallet"                    => 3,
            _                           => 1  // default COD
        };

        var row = await db.QuerySingleOrDefaultAsync<dynamic>(
            "usp_Commerce_Order_Place",
            new { UserId = userId, ShippingAddressId = addressId, PaymentMode = paymentMode,
                  CouponCode = string.IsNullOrWhiteSpace(couponCode) ? null : couponCode },
            commandType: System.Data.CommandType.StoredProcedure);

        return row is null ? 0 : (int)row.OrderId;
    }

    public async Task<List<OrderListItemDto>> GetOrdersAsync(int userId)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<OrderListRow>(
            "usp_Commerce_Order_GetByUser",
            new { UserId = userId, OrderStatus = (byte?)null, PageNumber = 1, PageSize = 50 },
            commandType: System.Data.CommandType.StoredProcedure);

        return rows.Select(r => new OrderListItemDto
        {
            Id            = r.OrderId,
            OrderNumber   = r.OrderNumber,
            Status        = MapOrderStatus((byte)r.OrderStatus),
            FinalAmount   = r.TotalAmount,
            PaymentMethod = r.PaymentMode.ToString(),
            CreatedAt     = r.OrderDate,
            ThumbnailUrl  = r.FirstProductImage,
            ItemCount     = r.ItemCount
        }).ToList();
    }

    public async Task<OrderDetailDto?> GetOrderDetailAsync(int orderId, int userId)
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Commerce_Order_GetById",
            new { OrderId = orderId, UserId = (int?)userId },
            commandType: System.Data.CommandType.StoredProcedure);

        var raw = await multi.ReadSingleOrDefaultAsync<dynamic>();
        if (raw is null) return null;

        var subTotal       = (decimal)raw.SubTotal;
        var discount       = (decimal)raw.DiscountAmount;
        var couponDiscount = (decimal)raw.CouponDiscount;
        var shipping       = (decimal)raw.ShippingCharge;
        var total          = (decimal)raw.TotalAmount;

        var order = new OrderDetailDto
        {
            Id             = (int)raw.OrderId,
            OrderNumber    = (string)raw.OrderNumber,
            Status         = MapOrderStatus((byte)raw.OrderStatus),
            PaymentMethod  = raw.PaymentMode.ToString(),
            PaymentStatus  = raw.PaymentStatus.ToString(),
            CreatedAt      = (DateTime)raw.OrderDate,
            TotalMRP       = subTotal,
            TotalDiscount  = discount,
            CouponDiscount = couponDiscount,
            CouponCode     = (string?)raw.CouponCode,
            DeliveryCharge = shipping,
            FinalAmount    = total,
            AddressLine1   = (string?)raw.AddressLine1,
            AddressLine2   = (string?)raw.AddressLine2,
            City           = (string?)raw.City,
            State          = (string?)raw.State,
            Pincode        = (string?)raw.PinCode
        };

        if (!multi.IsConsumed)
        {
            var itemRows = await multi.ReadAsync<dynamic>();
            order.Items = itemRows.Select(i =>
            {
                var dict = (IDictionary<string, object?>)i;
                byte lineStatus = dict.TryGetValue("LineStatus", out var ls) && ls is not null
                    ? Convert.ToByte(ls) : (byte)1;
                return new OrderItemDto
                {
                    Id              = (int)i.OrderItemId,
                    ProductId       = (int)i.ProductId,
                    ProductName     = (string)i.ProductName,
                    BrandName       = (string?)i.BrandName,
                    ImageUrl        = (string?)i.ProductImageUrl,
                    Quantity        = (int)i.Quantity,
                    SellingPrice    = (decimal)i.UnitPrice,
                    LineStatus      = lineStatus,
                    ConfirmedAt     = dict.TryGetValue("ConfirmedAt",     out var ca) ? ca as DateTime? : null,
                    RejectedAt      = dict.TryGetValue("RejectedAt",      out var ra) ? ra as DateTime? : null,
                    RejectionReason = dict.TryGetValue("RejectionReason", out var rr) ? rr as string   : null,
                };
            }).ToList();
        }

        // Third result set: append-only tracking timeline. SP returns
        // (TrackingId, OrderId, OrderItemId, Status, Note, ChangedAt, ChangedBy)
        // — map SP's Note → DTO's Description and ChangedAt → DTO's CreatedAt
        // so the UI's existing tracking shape doesn't change.
        if (!multi.IsConsumed)
        {
            var trackRows = await multi.ReadAsync<dynamic>();
            order.Tracking = trackRows.Select(t => new OrderTrackingDto
            {
                Status      = (string)t.Status,
                Description = (string?)t.Note,
                CreatedAt   = (DateTime)t.ChangedAt,
            }).ToList();
        }

        return order;
    }

    public async Task<OrderDetailDto?> CancelOrderByBuyerAsync(int orderId, int userId, string cancellationReason)
    {
        using var db = Conn();
        try
        {
            using var multi = await db.QueryMultipleAsync(
                "usp_Order_CancelByBuyer",
                new { OrderId = orderId, UserId = userId, CancellationReason = cancellationReason },
                commandType: System.Data.CommandType.StoredProcedure);

            var raw = await multi.ReadSingleOrDefaultAsync<dynamic>();
            if (raw is null) return null;

            var order = new OrderDetailDto
            {
                Id             = (int)raw.OrderId,
                OrderNumber    = (string)raw.OrderNumber,
                Status         = MapOrderStatus((byte)raw.OrderStatus),
                CreatedAt      = (DateTime)raw.CreatedAt,
                FinalAmount    = (decimal)raw.TotalAmount
            };

            return order;
        }
        catch (SqlException ex)
        {
            throw new InvalidOperationException(ex.Message);
        }
    }

    // DB stores OrderStatus as TINYINT; UI/API expect string labels.
    // 1=Pending→PLACED, 2=Confirmed, 3=Processing→PACKED, 4=Shipped→DISPATCHED,
    // 9=OutForDelivery, 5=Delivered, 6=Cancelled, 7=Returned, 8=Rejected.
    // Status 9 is currently only set on OrderItems (per-line) — Orders.OrderStatus
    // stays at 4 throughout — but the mapper handles it defensively in case
    // future code bumps the order header too.
    private static string MapOrderStatus(byte raw) => raw switch
    {
        1 => "PLACED",
        2 => "CONFIRMED",
        3 => "PACKED",
        4 => "DISPATCHED",
        9 => "OUT_FOR_DELIVERY",
        5 => "DELIVERED",
        6 => "CANCELLED",
        7 => "RETURNED",
        8 => "REJECTED",
        _ => raw.ToString(),
    };

    private sealed class OrderListRow
    {
        public int      OrderId           { get; set; }
        public string   OrderNumber       { get; set; } = string.Empty;
        public int      OrderStatus       { get; set; }
        public decimal  TotalAmount       { get; set; }
        public int      PaymentMode       { get; set; }
        public int      PaymentStatus     { get; set; }
        public DateTime OrderDate         { get; set; }
        public int      ItemCount         { get; set; }
        public string?  FirstProductImage { get; set; }
    }
}

public class AddressRepository(IConfiguration config) : IAddressRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<List<AddressDto>> GetAddressesAsync(int userId)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<AddressRow>(
            "usp_Auth_Address_GetByUser",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);

        return rows.Select(r => new AddressDto
        {
            Id           = r.AddressId,
            Name         = r.Label ?? string.Empty,
            Mobile       = r.Mobile ?? string.Empty,
            AddressLine1 = r.AddressLine1,
            AddressLine2 = r.AddressLine2,
            City         = r.City,
            State        = r.State,
            Pincode      = r.PinCode,
            IsDefault    = r.IsDefault
        }).ToList();
    }

    public async Task<int> AddAddressAsync(int userId, AddAddressRequest req)
    {
        using var db = Conn();
        var row = await db.QuerySingleOrDefaultAsync<AddressRow>(
            "usp_Auth_Address_Add",
            new
            {
                UserId       = userId,
                Label        = req.Name,
                req.AddressLine1,
                req.AddressLine2,
                req.City,
                req.State,
                PinCode      = req.Pincode,
                IsDefault    = req.IsDefault
            },
            commandType: System.Data.CommandType.StoredProcedure);

        return row?.AddressId ?? 0;
    }

    public async Task SetDefaultAddressAsync(int addressId, int userId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Auth_Address_SetDefault",
            new { AddressId = addressId, UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private sealed class AddressRow
    {
        public int     AddressId    { get; set; }
        public string? Label        { get; set; }
        public string? Mobile       { get; set; }
        public string  AddressLine1 { get; set; } = string.Empty;
        public string? AddressLine2 { get; set; }
        public string  City         { get; set; } = string.Empty;
        public string  State        { get; set; } = string.Empty;
        public string  PinCode      { get; set; } = string.Empty;
        public bool    IsDefault    { get; set; }
    }
}

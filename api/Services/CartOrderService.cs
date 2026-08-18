using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IWishlistService
{
    Task<List<WishlistItemDto>> GetWishlistAsync(int userId);
    Task<bool> ToggleWishlistAsync(int userId, int productId);
}

public interface ICartService
{
    Task<CartDto> GetCartAsync(int userId);
    Task<int> AddToCartAsync(int userId, AddToCartRequest req);
    Task<string> UpdateCartAsync(int cartId, int userId, int quantity);
    Task DeleteCartItemAsync(int cartId, int userId);
}

public interface IOrderService
{
    Task<int> PlaceOrderAsync(int userId, PlaceOrderRequest req);
    Task<List<OrderListItemDto>> GetOrdersAsync(int userId);
    Task<OrderDetailDto?> GetOrderDetailAsync(int orderId, int userId);
    Task<OrderDetailDto?> CancelOrderAsync(int orderId, int userId, string cancellationReason);
}

public interface IAddressService
{
    Task<List<AddressDto>> GetAddressesAsync(int userId);
    Task<int> AddAddressAsync(int userId, AddAddressRequest req);
    Task SetDefaultAddressAsync(int addressId, int userId);
}

// ---- Implementations ----

public class WishlistService(IWishlistRepository repo) : IWishlistService
{
    public Task<List<WishlistItemDto>> GetWishlistAsync(int userId) => repo.GetWishlistAsync(userId);
    public Task<bool> ToggleWishlistAsync(int userId, int productId) => repo.ToggleWishlistAsync(userId, productId);
}

public class CartService(ICartRepository repo) : ICartService
{
    public Task<CartDto> GetCartAsync(int userId) => repo.GetCartAsync(userId);
    public Task<int> AddToCartAsync(int userId, AddToCartRequest req) => repo.AddToCartAsync(userId, req);
    public Task<string> UpdateCartAsync(int cartId, int userId, int quantity) => repo.UpdateCartAsync(cartId, userId, quantity);
    public Task DeleteCartItemAsync(int cartId, int userId) => repo.DeleteCartItemAsync(cartId, userId);
}

public class OrderService(
    IOrderRepository repo,
    IEmailService emailService,
    IAuthRepository authRepo) : IOrderService
{
    public async Task<int> PlaceOrderAsync(int userId, PlaceOrderRequest req)
    {
        var orderId = await repo.PlaceOrderAsync(userId, req.AddressId, req.PaymentMethod, req.CouponCode);
        if (orderId > 0)
        {
            // Fire-and-forget: never block the order response waiting for email
            _ = Task.Run(async () =>
            {
                try
                {
                    var profileTask = authRepo.GetProfileAsync(userId);
                    var orderTask   = repo.GetOrderDetailAsync(orderId, userId);
                    await Task.WhenAll(profileTask, orderTask);

                    var profile = profileTask.Result;
                    var order   = orderTask.Result;
                    if (profile is not null && order is not null)
                    {
                        var name  = $"{profile.FirstName} {profile.LastName}".Trim();
                        await emailService.SendOrderConfirmationAsync(
                            profile.Email ?? string.Empty,
                            string.IsNullOrWhiteSpace(name) ? "Valued Customer" : name,
                            orderId,
                            order.OrderNumber,
                            order.FinalAmount);
                    }
                }
                catch { /* swallow — email must never break order flow */ }
            });
        }
        return orderId;
    }

    public Task<List<OrderListItemDto>> GetOrdersAsync(int userId) => repo.GetOrdersAsync(userId);
    public Task<OrderDetailDto?> GetOrderDetailAsync(int orderId, int userId) => repo.GetOrderDetailAsync(orderId, userId);

    public async Task<OrderDetailDto?> CancelOrderAsync(int orderId, int userId, string cancellationReason)
    {
        var order = await repo.CancelOrderByBuyerAsync(orderId, userId, cancellationReason);
        if (order is not null)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    var profile = await authRepo.GetProfileAsync(userId);
                    if (profile is not null)
                    {
                        var name = $"{profile.FirstName} {profile.LastName}".Trim();
                        await emailService.SendOrderCancellationAsync(
                            profile.Email ?? string.Empty,
                            string.IsNullOrWhiteSpace(name) ? "Valued Customer" : name,
                            order.Id,
                            order.OrderNumber,
                            order.FinalAmount,
                            false); // COD doesn't refund to wallet
                    }
                }
                catch { /* swallow — email must never break order flow */ }
            });
        }
        return order;
    }
}

public class AddressService(IAddressRepository repo) : IAddressService
{
    public Task<List<AddressDto>> GetAddressesAsync(int userId) => repo.GetAddressesAsync(userId);
    public Task<int> AddAddressAsync(int userId, AddAddressRequest req) => repo.AddAddressAsync(userId, req);
    public Task SetDefaultAddressAsync(int addressId, int userId) => repo.SetDefaultAddressAsync(addressId, userId);
}

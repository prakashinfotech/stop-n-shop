using System.Reflection;
using System.Text;
using System.Text.Json;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Middleware;
using ShopNShop.Api.Repositories;
using ShopNShop.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title       = "ShopNShop API",
        Version     = "v1",
        Description = "REST API for the StopNShop e-commerce platform. All protected endpoints require a Bearer JWT token obtained via POST /api/auth/verify-otp."
    });

    // Include XML doc comments
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath)) c.IncludeXmlComments(xmlPath);

    c.AddSecurityDefinition("Bearer", new()
    {
        Name         = "Authorization",
        Type         = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme       = "Bearer",
        BearerFormat = "JWT",
        In           = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description  = "Enter your JWT token (without 'Bearer ' prefix)"
    });
    c.AddSecurityRequirement(new()
    {
        {
            new() { Reference = new() { Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme, Id = "Bearer" } },
            []
        }
    });
});

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:SecretKey"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opts =>
    {
        opts.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateIssuer           = true,
            ValidIssuer              = builder.Configuration["Jwt:Issuer"],
            ValidateAudience         = true,
            ValidAudience            = builder.Configuration["Jwt:Audience"],
            ValidateLifetime         = true,
            ClockSkew                = TimeSpan.Zero
        };
        opts.SecurityTokenValidators.Clear();
        opts.SecurityTokenValidators.Add(new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler
        {
            MapInboundClaims = false
        });
    });

builder.Services.AddAuthorization();

// CORS — allow UI dev server
builder.Services.AddCors(opts =>
    opts.AddDefaultPolicy(p => p
        .WithOrigins(builder.Configuration["AllowedOrigins"]?.Split(',') ?? ["http://localhost:5173"])
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials()));

// Repositories
builder.Services.AddScoped<IAuthRepository,          AuthRepository>();
builder.Services.AddScoped<IBrandRepository,         BrandRepository>();
builder.Services.AddScoped<ICatalogueRepository,     CatalogueRepository>();
builder.Services.AddScoped<IProductRepository,       ProductRepository>();
builder.Services.AddScoped<IWishlistRepository,      WishlistRepository>();
builder.Services.AddScoped<ICartRepository,          CartRepository>();
builder.Services.AddScoped<IOrderRepository,         OrderRepository>();
builder.Services.AddScoped<IAddressRepository,       AddressRepository>();
// Seller repositories
builder.Services.AddScoped<ISellerRepository,           SellerRepository>();
builder.Services.AddScoped<ISellerProductRepository,    SellerProductRepository>();
builder.Services.AddScoped<ISellerOrderRepository,      SellerOrderRepository>();
builder.Services.AddScoped<ISellerDashboardRepository,  SellerDashboardRepository>();
builder.Services.AddScoped<ISellerLifecycleRepository,  SellerLifecycleRepository>();
// New feature repositories
builder.Services.AddScoped<ICouponRepository,           CouponRepository>();
builder.Services.AddScoped<IComplaintRepository,        ComplaintRepository>();
builder.Services.AddScoped<IEngagementRepository,       EngagementRepository>();
builder.Services.AddScoped<INotificationRepository,     NotificationRepository>();
builder.Services.AddScoped<IWalletRepository,           WalletRepository>();
builder.Services.AddScoped<IAdminRepository,            AdminRepository>();
builder.Services.AddScoped<IAdminCategoryRepository,    AdminCategoryRepository>();
builder.Services.AddScoped<IVariantLibraryRepository,   VariantLibraryRepository>();
builder.Services.AddScoped<IInventoryRepository,        InventoryRepository>();
builder.Services.AddScoped<IDispatcherRepository,       DispatcherRepository>();

// Services
builder.Services.AddScoped<IAuthService,             AuthService>();
builder.Services.AddScoped<IBrandService,            BrandService>();
builder.Services.AddScoped<ICatalogueService,        CatalogueService>();
builder.Services.AddScoped<IProductService,          ProductService>();
builder.Services.AddScoped<IWishlistService,         WishlistService>();
builder.Services.AddScoped<ICartService,             CartService>();
builder.Services.AddScoped<IOrderService,            OrderService>();
builder.Services.AddScoped<IAddressService,          AddressService>();
// Seller services
builder.Services.AddScoped<ISellerAuthService,       SellerAuthService>();
builder.Services.AddScoped<ISellerProductService,    SellerProductService>();
builder.Services.AddScoped<ISellerDashboardService,  SellerDashboardService>();
builder.Services.AddScoped<ISellerOrderService,      SellerOrderService>();
builder.Services.AddScoped<ISellerLifecycleService,  SellerLifecycleService>();
builder.Services.AddHostedService<SellerSettlementWorker>();
builder.Services.AddHostedService<SellerScoreWorker>();
// New feature services
builder.Services.AddScoped<ICouponService,           CouponService>();
builder.Services.AddScoped<IComplaintService,        ComplaintService>();
builder.Services.AddScoped<IEngagementService,       EngagementService>();
builder.Services.AddScoped<INotificationService,     NotificationService>();
builder.Services.AddScoped<IWalletService,           WalletService>();
builder.Services.AddScoped<IAdminService,            AdminService>();
builder.Services.AddScoped<IAdminCategoryService,    AdminCategoryService>();
builder.Services.AddScoped<IVariantLibraryService,   VariantLibraryService>();
builder.Services.AddSingleton<IEmailService,         EmailService>();
builder.Services.AddSingleton<ISmsService,           SmsService>();
// Inventory
builder.Services.AddScoped<IInventoryService,        InventoryService>();
// Dispatcher (warehouse-to-doorstep logistics)
builder.Services.AddScoped<IDispatcherService,       DispatcherService>();
builder.Services.AddScoped<IValidator<StockAdjustRequest>,            StockAdjustRequestValidator>();
builder.Services.AddScoped<IValidator<StockReserveRequest>,           StockReserveRequestValidator>();
builder.Services.AddScoped<IValidator<StockTransferInitiateRequest>,  StockTransferInitiateRequestValidator>();
builder.Services.AddHostedService<ReservationExpiryWorker>();

// FluentValidation: registered manually to avoid the DI extension package.
// Validators are injected as IValidator<TRequest> and invoked explicitly from
// services that take untrusted input.
builder.Services.AddScoped<IValidator<ShopNShop.Api.DTOs.SellerRejectItemRequest>,   ShopNShop.Api.Validators.SellerRejectItemRequestValidator>();
builder.Services.AddScoped<IValidator<ShopNShop.Api.DTOs.UpdateCouponRequest>,       ShopNShop.Api.Validators.UpdateCouponRequestValidator>();
builder.Services.AddScoped<IValidator<ShopNShop.Api.DTOs.ForceCancelOrderRequest>,   ShopNShop.Api.Validators.ForceCancelOrderRequestValidator>();
builder.Services.AddScoped<IValidator<ShopNShop.Api.DTOs.ManualRefundRequest>,       ShopNShop.Api.Validators.ManualRefundRequestValidator>();

builder.Services.AddHttpClient(); // Razorpay order creation

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();
app.UseStaticFiles();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

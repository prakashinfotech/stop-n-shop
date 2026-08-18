using FluentValidation;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Validators;

public class SellerSignupRequestValidator : AbstractValidator<SellerSignupRequest>
{
    public SellerSignupRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Email format is invalid.");

        RuleFor(x => x.PhoneNumber)
            .NotEmpty().WithMessage("Phone number is required.")
            .Matches(@"^\d{10}$").WithMessage("Phone number must be 10 digits.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters.")
            .Matches(@"[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
            .Matches(@"[0-9]").WithMessage("Password must contain at least one digit.");

        RuleFor(x => x.ConfirmPassword)
            .NotEmpty().WithMessage("Confirm password is required.")
            .Equal(x => x.Password).WithMessage("Passwords do not match.");
    }
}

public class SellerLoginRequestValidator : AbstractValidator<SellerLoginRequest>
{
    public SellerLoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("Email format is invalid.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.");
    }
}

public class CreateSellerProductRequestValidator : AbstractValidator<CreateSellerProductRequest>
{
    public CreateSellerProductRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Product name is required.")
            .MaximumLength(300).WithMessage("Product name must not exceed 300 characters.");

        RuleFor(x => x.Description)
            .MaximumLength(4000).WithMessage("Description must not exceed 4000 characters.");

        RuleFor(x => x.ProductTypeId)
            .GreaterThan(0).WithMessage("A valid product type is required.");

        RuleFor(x => x.MRP)
            .GreaterThan(0).WithMessage("MRP must be greater than zero.");

        RuleFor(x => x.SellingPrice)
            .GreaterThan(0).WithMessage("Selling price must be greater than zero.");

        RuleFor(x => x.StockQuantity)
            .GreaterThanOrEqualTo(0).WithMessage("Stock quantity cannot be negative.");

        RuleFor(x => x.LowStockThreshold)
            .GreaterThanOrEqualTo(0).WithMessage("Low stock threshold cannot be negative.");
    }
}

public class UpdateSellerProductRequestValidator : AbstractValidator<UpdateSellerProductRequest>
{
    public UpdateSellerProductRequestValidator()
    {
        RuleFor(x => x.Name)
            .MaximumLength(300).WithMessage("Product name must not exceed 300 characters.")
            .When(x => !string.IsNullOrEmpty(x.Name));

        RuleFor(x => x.Description)
            .MaximumLength(4000).WithMessage("Description must not exceed 4000 characters.")
            .When(x => !string.IsNullOrEmpty(x.Description));

        RuleFor(x => x.MRP)
            .GreaterThan(0).WithMessage("MRP must be greater than zero.")
            .When(x => x.MRP.HasValue);

        RuleFor(x => x.SellingPrice)
            .GreaterThan(0).WithMessage("Selling price must be greater than zero.")
            .When(x => x.SellingPrice.HasValue);

        RuleFor(x => x.StockQuantity)
            .GreaterThanOrEqualTo(0).WithMessage("Stock quantity cannot be negative.")
            .When(x => x.StockQuantity.HasValue);
    }
}

public class UpdateInventoryRequestValidator : AbstractValidator<UpdateInventoryRequest>
{
    public UpdateInventoryRequestValidator()
    {
        RuleFor(x => x.StockQuantity)
            .GreaterThanOrEqualTo(0).WithMessage("Stock quantity cannot be negative.")
            .When(x => x.StockQuantity.HasValue);

        RuleFor(x => x.LowStockThreshold)
            .GreaterThanOrEqualTo(0).WithMessage("Low stock threshold cannot be negative.")
            .When(x => x.LowStockThreshold.HasValue);
    }
}

public class SellerOnboardingRequestValidator : AbstractValidator<SellerOnboardingRequest>
{
    public SellerOnboardingRequestValidator()
    {
        RuleFor(x => x.OwnerFullName)
            .NotEmpty().WithMessage("Owner full name is required.")
            .MaximumLength(255).WithMessage("Owner full name must not exceed 255 characters.");

        RuleFor(x => x.DisplayName)
            .NotEmpty().WithMessage("Display name is required.")
            .MaximumLength(255).WithMessage("Display name must not exceed 255 characters.");

        RuleFor(x => x.StoreDescription)
            .NotEmpty().WithMessage("Store description is required.")
            .MaximumLength(2000).WithMessage("Store description must not exceed 2000 characters.");

        RuleFor(x => x.PickupAddressLine1)
            .NotEmpty().WithMessage("Pickup address is required.")
            .MaximumLength(255).WithMessage("Pickup address must not exceed 255 characters.");

        RuleFor(x => x.PickupCity)
            .NotEmpty().WithMessage("Pickup city is required.")
            .MaximumLength(100).WithMessage("Pickup city must not exceed 100 characters.");

        RuleFor(x => x.PickupState)
            .NotEmpty().WithMessage("Pickup state is required.")
            .MaximumLength(100).WithMessage("Pickup state must not exceed 100 characters.");

        RuleFor(x => x.PickupPincode)
            .NotEmpty().WithMessage("Pickup pincode is required.")
            .Matches(@"^\d{6}$").WithMessage("Pickup pincode must be 6 digits.");

        RuleFor(x => x.SelectedCategoryIds)
            .Must(x => x.Count > 0).WithMessage("Please select at least one category.")
            .When(x => !x.AllCategories);
    }
}

public class SellerRejectItemRequestValidator : AbstractValidator<SellerRejectItemRequest>
{
    public SellerRejectItemRequestValidator()
    {
        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("A rejection reason is required.")
            .MinimumLength(10).WithMessage("Please give the buyer a clear reason (at least 10 characters).")
            .MaximumLength(500).WithMessage("Reason cannot exceed 500 characters.");
    }
}

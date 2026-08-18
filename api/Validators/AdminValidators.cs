using FluentValidation;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Validators;

public class UpdateCouponRequestValidator : AbstractValidator<UpdateCouponRequest>
{
    public UpdateCouponRequestValidator()
    {
        RuleFor(x => x.CouponCode)
            .NotEmpty().WithMessage("Coupon code is required.")
            .MaximumLength(50);

        RuleFor(x => x.OfferName)
            .NotEmpty().WithMessage("Offer name is required.")
            .MaximumLength(300);

        RuleFor(x => x.OfferType)
            .InclusiveBetween((byte)1, (byte)2)
            .WithMessage("Offer type must be 1 (Flat) or 2 (Percentage).");

        RuleFor(x => x.DiscountValue)
            .GreaterThan(0).WithMessage("Discount value must be greater than zero.");

        RuleFor(x => x.DiscountValue)
            .LessThanOrEqualTo(100)
            .When(x => x.OfferType == 2)
            .WithMessage("Percentage discount cannot exceed 100.");

        RuleFor(x => x.MinOrderValue)
            .GreaterThanOrEqualTo(0);

        RuleFor(x => x.EndDate)
            .GreaterThan(x => x.StartDate)
            .WithMessage("End date must be after start date.");

        RuleFor(x => x.ApplicableOn)
            .InclusiveBetween((byte)1, (byte)4);

        RuleFor(x => x.EntityId)
            .NotNull()
            .When(x => x.ApplicableOn == 2)
            .WithMessage("Brand-specific coupons require a brand id.");

        RuleFor(x => x.UsageLimitPerUser)
            .GreaterThan((byte)0);
    }
}

public class ForceCancelOrderRequestValidator : AbstractValidator<ForceCancelOrderRequest>
{
    public ForceCancelOrderRequestValidator()
    {
        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("A cancellation reason is required.")
            .MaximumLength(500);
    }
}

public class ManualRefundRequestValidator : AbstractValidator<ManualRefundRequest>
{
    public ManualRefundRequestValidator()
    {
        RuleFor(x => x.RefundAmount)
            .GreaterThan(0).WithMessage("Refund amount must be positive.");

        RuleFor(x => x.Reason)
            .NotEmpty().WithMessage("A refund reason is required.")
            .MaximumLength(500);

        RuleFor(x => x.GatewayRef)
            .MaximumLength(200);
    }
}

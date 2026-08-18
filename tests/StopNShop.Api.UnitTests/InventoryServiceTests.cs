using FluentAssertions;
using FluentValidation;
using Moq;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;
using ShopNShop.Api.Services;
using Xunit;

namespace StopNShop.Api.UnitTests;

/// <summary>
/// Unit tests for <see cref="InventoryService"/> — verifies that mutating ops
/// run validation, hit the repository, and write a matching AuditLogs entry.
/// No live DB or API is required; the repository is mocked.
/// </summary>
public class InventoryServiceTests
{
    private readonly Mock<IInventoryRepository> _repo = new();
    private readonly InventoryService _sut;

    public InventoryServiceTests()
    {
        _sut = new InventoryService(
            _repo.Object,
            new StockAdjustRequestValidator(),
            new StockReserveRequestValidator(),
            new StockTransferInitiateRequestValidator());
    }

    // ── AdjustStockAsync ─────────────────────────────────────────────────────

    [Fact]
    public async Task AdjustStockAsync_validates_and_writes_audit_on_success()
    {
        var req = new StockAdjustRequest
        {
            VariantId     = 1,
            WarehouseId   = 2,
            QuantityDelta = 10,
            Reason        = "Cycle count",
            MovementType  = 2,
        };

        _repo.Setup(r => r.AdjustStockAsync(1, 2, 10, "Cycle count", (byte)2, "Manual", null, 99))
             .ReturnsAsync((42, 110, 0));

        var (onHand, reserved) = await _sut.AdjustStockAsync(req, changedBy: 99, ip: "127.0.0.1");

        onHand.Should().Be(110);
        reserved.Should().Be(0);

        _repo.Verify(r => r.WriteAuditAsync(
            "Stock", 42, "UPDATE",
            null,
            It.Is<string>(s => s.Contains("ADJUST_STOCK")),
            99, "127.0.0.1"), Times.Once);
    }

    [Fact]
    public async Task AdjustStockAsync_rejects_zero_delta()
    {
        var req = new StockAdjustRequest { VariantId = 1, WarehouseId = 1, QuantityDelta = 0, MovementType = 2 };

        var act = () => _sut.AdjustStockAsync(req, 99, null);

        await act.Should().ThrowAsync<ValidationException>();
        _repo.Verify(r => r.AdjustStockAsync(It.IsAny<int>(), It.IsAny<int>(), It.IsAny<int>(),
            It.IsAny<string?>(), It.IsAny<byte>(), It.IsAny<string?>(), It.IsAny<long?>(), It.IsAny<int>()),
            Times.Never);
    }

    [Fact]
    public async Task AdjustStockAsync_rejects_unknown_movement_type()
    {
        var req = new StockAdjustRequest { VariantId = 1, WarehouseId = 1, QuantityDelta = 5, MovementType = 5 };

        var act = () => _sut.AdjustStockAsync(req, 99, null);

        await act.Should().ThrowAsync<ValidationException>();
    }

    // ── ReserveAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task ReserveAsync_writes_audit_with_reservation_id()
    {
        var req = new StockReserveRequest { VariantId = 1, WarehouseId = 2, Quantity = 3, TtlMinutes = 15 };
        var expires = DateTime.UtcNow.AddMinutes(15);

        _repo.Setup(r => r.ReserveAsync(1, 2, 3, 99, null, 15, 99))
             .ReturnsAsync(new StockReserveResult { ReservationId = 777, ExpiresAt = expires });

        var result = await _sut.ReserveAsync(req, userId: 99, changedBy: 99, ip: null);

        result.ReservationId.Should().Be(777);
        _repo.Verify(r => r.WriteAuditAsync("StockReservations", 777, "UPDATE",
            null, It.Is<string>(s => s.Contains("RESERVE_STOCK")), 99, null), Times.Once);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task ReserveAsync_rejects_non_positive_quantity(int qty)
    {
        var req = new StockReserveRequest { VariantId = 1, WarehouseId = 1, Quantity = qty, TtlMinutes = 15 };
        await Assert.ThrowsAsync<ValidationException>(() => _sut.ReserveAsync(req, 1, 1, null));
    }

    [Fact]
    public async Task ReserveAsync_rejects_ttl_above_limit()
    {
        var req = new StockReserveRequest { VariantId = 1, WarehouseId = 1, Quantity = 1, TtlMinutes = 999 };
        await Assert.ThrowsAsync<ValidationException>(() => _sut.ReserveAsync(req, 1, 1, null));
    }

    // ── ReleaseAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task ReleaseAsync_logs_release_when_no_commit_target()
    {
        var req = new StockReleaseRequest { ReservationId = 50 };
        await _sut.ReleaseAsync(req, 99, null);

        _repo.Verify(r => r.ReleaseReservationAsync(50, null, null, 99), Times.Once);
        _repo.Verify(r => r.WriteAuditAsync("StockReservations", 50, "UPDATE",
            null, It.Is<string>(s => s.Contains("RELEASE_RESERVATION")), 99, null), Times.Once);
    }

    [Fact]
    public async Task ReleaseAsync_logs_commit_when_order_id_provided()
    {
        var req = new StockReleaseRequest { ReservationId = 50, CommitToOrderId = 7 };
        await _sut.ReleaseAsync(req, 99, null);

        _repo.Verify(r => r.WriteAuditAsync("StockReservations", 50, "UPDATE",
            null, It.Is<string>(s => s.Contains("COMMIT_RESERVATION")), 99, null), Times.Once);
    }

    // ── Transfers ────────────────────────────────────────────────────────────

    [Fact]
    public async Task InitiateTransfer_validates_distinct_warehouses()
    {
        var req = new StockTransferInitiateRequest
        {
            VariantId = 1, FromWarehouseId = 5, ToWarehouseId = 5, Quantity = 2,
        };

        await Assert.ThrowsAsync<ValidationException>(() => _sut.InitiateTransferAsync(req, 99, null));
    }

    [Fact]
    public async Task InitiateTransfer_writes_audit_with_returned_id()
    {
        var req = new StockTransferInitiateRequest
        {
            VariantId = 1, FromWarehouseId = 5, ToWarehouseId = 6, Quantity = 2,
        };

        _repo.Setup(r => r.InitiateTransferAsync(1, 5, 6, 2, null, 99)).ReturnsAsync(321);

        var id = await _sut.InitiateTransferAsync(req, 99, "10.0.0.1");

        id.Should().Be(321);
        _repo.Verify(r => r.WriteAuditAsync("StockTransfers", 321, "UPDATE",
            null, It.Is<string>(s => s.Contains("TRANSFER_INITIATE")), 99, "10.0.0.1"), Times.Once);
    }

    [Fact]
    public async Task ReceiveTransfer_records_audit_entry()
    {
        await _sut.ReceiveTransferAsync(321, 99, null);

        _repo.Verify(r => r.ReceiveTransferAsync(321, 99), Times.Once);
        _repo.Verify(r => r.WriteAuditAsync("StockTransfers", 321, "UPDATE",
            null, It.Is<string>(s => s.Contains("TRANSFER_RECEIVE")), 99, null), Times.Once);
    }

    // ── Reads pass through ───────────────────────────────────────────────────

    [Fact]
    public async Task GetStockMatrixAsync_passes_filters_through()
    {
        _repo.Setup(r => r.GetStockMatrixAsync(7, 1, "tee", 2, 25))
             .ReturnsAsync((new List<StockMatrixRowDto>(), 0));

        await _sut.GetStockMatrixAsync(7, 1, "tee", 2, 25);

        _repo.Verify(r => r.GetStockMatrixAsync(7, 1, "tee", 2, 25), Times.Once);
    }
}

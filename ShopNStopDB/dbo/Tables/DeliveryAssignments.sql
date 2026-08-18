-- One row per (OrderItem, Dispatcher) pickup-to-delivery handoff. The
-- "current" assignment for an item is the latest non-failed row; failed
-- attempts that get retried produce a new row (so we keep history without
-- mutating the original).
--
-- Status mirrors OrderItems.OrderStatus for the in-transit phase so the buyer
-- + admin can see the same labels: 10 PickedUp / 4 Dispatched / 9 OFD / 5
-- Delivered / 11 DeliveryFailed / 12 RTO. We store it here too so the
-- Dispatcher's queue can be queried without joining back to OrderItems.
CREATE TABLE [dbo].[DeliveryAssignments]
(
    [AssignmentId]      INT             NOT NULL  IDENTITY(1,1),
    [OrderItemId]       INT             NOT NULL,
    [DispatcherId]      INT             NOT NULL,
    [WarehouseId]       INT             NOT NULL,         -- source warehouse (snapshot)
    [Status]            TINYINT         NOT NULL  CONSTRAINT [DF_DA_Status] DEFAULT 10,
                                                          -- 10 PickedUp | 4 Dispatched | 9 OFD | 5 Delivered | 11 Failed | 12 RTO

    [AssignedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DA_AssignedAt] DEFAULT GETUTCDATE(),
    [PickedUpAt]        DATETIME2(0)    NULL,
    [OutForDeliveryAt]  DATETIME2(0)    NULL,
    [DeliveredAt]       DATETIME2(0)    NULL,

    -- Delivery completion proof
    [DeliveryOtp]            NVARCHAR(6)  NULL,            -- generated on Send OTP, cleared on successful delivery
    [DeliveryOtpSentAt]      DATETIME2(0) NULL,
    [DeliveryOtpAttempts]    TINYINT      NOT NULL CONSTRAINT [DF_DA_OtpAttempts] DEFAULT 0,  -- wrong-entry counter
    [DeliveryOtpLockedUntil] DATETIME2(0) NULL,            -- set after 3 wrong attempts (5-min cool-off)
    [DeliveryProofUrl]  NVARCHAR(500)   NULL,             -- photo / signature blob URL
    [DeliveryGpsLat]    DECIMAL(9,6)    NULL,
    [DeliveryGpsLng]    DECIMAL(9,6)    NULL,

    -- COD reconciliation (NULL = not a COD order, or not yet collected)
    [CodAmount]         DECIMAL(18,2)   NULL,             -- amount expected, set at assignment time for COD
    [CodCollected]      DECIMAL(18,2)   NULL,             -- amount actually received
    [CodSettledAt]      DATETIME2(0)    NULL,             -- when dispatcher deposited to admin

    -- Failure / RTO
    [FailureReason]     NVARCHAR(500)   NULL,
    [AttemptNumber]     TINYINT         NOT NULL  CONSTRAINT [DF_DA_AttemptNumber] DEFAULT 1,

    [CreatedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DA_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DA_UpdatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_DeliveryAssignments]              PRIMARY KEY CLUSTERED ([AssignmentId] ASC),
    CONSTRAINT [CK_DA_Status]                        CHECK ([Status] IN (10, 4, 9, 5, 11, 12)),
    CONSTRAINT [FK_DA_OrderItemId]                   FOREIGN KEY ([OrderItemId])  REFERENCES [dbo].[OrderItems]  ([OrderItemId]),
    CONSTRAINT [FK_DA_DispatcherId]                  FOREIGN KEY ([DispatcherId]) REFERENCES [dbo].[Dispatchers] ([DispatcherId]),
    CONSTRAINT [FK_DA_WarehouseId]                   FOREIGN KEY ([WarehouseId])  REFERENCES [dbo].[Warehouses]  ([WarehouseId])
);
GO

-- Dispatcher's "today" queries — by dispatcher + open status, ordered by age.
CREATE NONCLUSTERED INDEX [IX_DA_Dispatcher_Active]
    ON [dbo].[DeliveryAssignments] ([DispatcherId] ASC, [Status] ASC, [AssignedAt] DESC)
    INCLUDE ([OrderItemId], [WarehouseId]);
GO

-- Reverse lookup — "what's the current assignment for this order item?"
CREATE NONCLUSTERED INDEX [IX_DA_OrderItem]
    ON [dbo].[DeliveryAssignments] ([OrderItemId] ASC, [AssignedAt] DESC);
GO

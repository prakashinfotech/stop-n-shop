-- Time-series ping log from the dispatcher's phone while a parcel is in
-- transit (status 4/9). High write volume (~1 ping per 30s per active
-- assignment). Buyer-facing reads go to DispatcherCurrentPositions instead;
-- this table is for audit + retroactive route review.
--
-- Retention: a nightly job (usp_Dispatcher_Location_Purge) deletes rows
-- older than 30 days.
CREATE TABLE [dbo].[DispatcherLocationPings]
(
    [PingId]         BIGINT          NOT NULL  IDENTITY(1,1),
    [AssignmentId]   INT             NOT NULL,
    [DispatcherId]   INT             NOT NULL,
    [Lat]            DECIMAL(9,6)    NOT NULL,
    [Lng]            DECIMAL(9,6)    NOT NULL,
    [Heading]        DECIMAL(5,2)    NULL,             -- 0-360°
    [SpeedKmh]       DECIMAL(5,2)    NULL,
    [Accuracy]       DECIMAL(7,2)    NULL,             -- GPS accuracy in metres
    [BatteryPct]     TINYINT         NULL,             -- helps debug stale pings
    [CapturedAt]     DATETIME2(0)    NOT NULL,         -- captured client-side
    [ReceivedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DLP_ReceivedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_DispatcherLocationPings]   PRIMARY KEY CLUSTERED ([PingId] ASC),
    CONSTRAINT [FK_DLP_AssignmentId]          FOREIGN KEY ([AssignmentId]) REFERENCES [dbo].[DeliveryAssignments] ([AssignmentId]),
    CONSTRAINT [FK_DLP_DispatcherId]          FOREIGN KEY ([DispatcherId]) REFERENCES [dbo].[Dispatchers]         ([DispatcherId])
);
GO

-- Latest-N-pings-for-an-assignment is the common audit query.
CREATE NONCLUSTERED INDEX [IX_DLP_Assignment_Captured]
    ON [dbo].[DispatcherLocationPings] ([AssignmentId] ASC, [CapturedAt] DESC);
GO

-- Retention purge scans by ReceivedAt.
CREATE NONCLUSTERED INDEX [IX_DLP_ReceivedAt]
    ON [dbo].[DispatcherLocationPings] ([ReceivedAt] ASC);
GO

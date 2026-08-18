-- Materialised "latest location per active assignment". Buyer's live-map
-- card reads this — O(1) lookup, no aggregation. Same SP that inserts a
-- new ping row also UPSERTs this one. Row is deleted when the assignment
-- terminates (status 5 Delivered, 11 DeliveryFailed final attempt, or 12 RTO).
--
-- Privacy: dispatcher's location is only fetched via usp_Order_Tracking_GetLive
-- which enforces (assignment is in status 9 OR 4) AND (caller is the buyer
-- of the order). No raw access outside that SP.
CREATE TABLE [dbo].[DispatcherCurrentPositions]
(
    [AssignmentId]  INT             NOT NULL,
    [Lat]           DECIMAL(9,6)    NOT NULL,
    [Lng]           DECIMAL(9,6)    NOT NULL,
    [Heading]       DECIMAL(5,2)    NULL,
    [SpeedKmh]      DECIMAL(5,2)    NULL,
    [EtaMinutes]    INT             NULL,             -- server-side haversine + 30 km/h cap
    [UpdatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DCP_UpdatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_DispatcherCurrentPositions]   PRIMARY KEY CLUSTERED ([AssignmentId] ASC),
    CONSTRAINT [FK_DCP_AssignmentId]             FOREIGN KEY ([AssignmentId]) REFERENCES [dbo].[DeliveryAssignments] ([AssignmentId])
);
GO

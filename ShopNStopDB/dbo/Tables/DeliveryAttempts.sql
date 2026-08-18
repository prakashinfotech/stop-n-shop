-- Append-only log of every delivery attempt under a single assignment.
-- Lets us count attempts before triggering RTO ("3 strikes and out") and
-- gives ops a forensic trail when buyers dispute failed deliveries.
CREATE TABLE [dbo].[DeliveryAttempts]
(
    [AttemptId]              INT             NOT NULL  IDENTITY(1,1),
    [AssignmentId]           INT             NOT NULL,
    [AttemptNumber]          TINYINT         NOT NULL,        -- 1, 2, 3...
    [AttemptedAt]            DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DAtt_AttemptedAt] DEFAULT GETUTCDATE(),
    [Outcome]                NVARCHAR(30)    NOT NULL,        -- DELIVERED | NOT_HOME | WRONG_ADDR | REFUSED | OTP_FAIL | OTHER
    [Notes]                  NVARCHAR(500)   NULL,
    [GpsLat]                 DECIMAL(9,6)    NULL,
    [GpsLng]                 DECIMAL(9,6)    NULL,
    [NextAttemptScheduledAt] DATETIME2(0)    NULL,             -- non-null only if Outcome != DELIVERED

    CONSTRAINT [PK_DeliveryAttempts]              PRIMARY KEY CLUSTERED ([AttemptId] ASC),
    CONSTRAINT [CK_DAtt_Outcome]                  CHECK ([Outcome] IN
        (N'DELIVERED', N'NOT_HOME', N'WRONG_ADDR', N'REFUSED', N'OTP_FAIL', N'OTHER')),
    CONSTRAINT [FK_DAtt_AssignmentId]             FOREIGN KEY ([AssignmentId])
        REFERENCES [dbo].[DeliveryAssignments] ([AssignmentId])
);
GO

CREATE NONCLUSTERED INDEX [IX_DAtt_AssignmentId]
    ON [dbo].[DeliveryAttempts] ([AssignmentId] ASC, [AttemptNumber] ASC);
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
-- 50 real Ahmedabad-area serviceable pincodes. Idempotent via MERGE on [Pincode].
MERGE [dbo].[Pincodes] AS tgt
USING (VALUES
    (N'380001', N'Ahmedabad', N'Gujarat', 2),
    (N'380002', N'Ahmedabad', N'Gujarat', 2),
    (N'380003', N'Ahmedabad', N'Gujarat', 2),
    (N'380004', N'Ahmedabad', N'Gujarat', 2),
    (N'380005', N'Ahmedabad', N'Gujarat', 2),
    (N'380006', N'Ahmedabad', N'Gujarat', 2),
    (N'380007', N'Ahmedabad', N'Gujarat', 2),
    (N'380008', N'Ahmedabad', N'Gujarat', 2),
    (N'380009', N'Ahmedabad', N'Gujarat', 2),
    (N'380013', N'Ahmedabad', N'Gujarat', 2),
    (N'380014', N'Ahmedabad', N'Gujarat', 2),
    (N'380015', N'Ahmedabad', N'Gujarat', 2),
    (N'380016', N'Ahmedabad', N'Gujarat', 2),
    (N'380018', N'Ahmedabad', N'Gujarat', 2),
    (N'380019', N'Ahmedabad', N'Gujarat', 2),
    (N'380021', N'Ahmedabad', N'Gujarat', 3),
    (N'380022', N'Ahmedabad', N'Gujarat', 3),
    (N'380023', N'Ahmedabad', N'Gujarat', 3),
    (N'380024', N'Ahmedabad', N'Gujarat', 3),
    (N'380026', N'Ahmedabad', N'Gujarat', 3),
    (N'380027', N'Ahmedabad', N'Gujarat', 3),
    (N'380028', N'Ahmedabad', N'Gujarat', 3),
    (N'380043', N'Ahmedabad', N'Gujarat', 3),
    (N'380045', N'Ahmedabad', N'Gujarat', 3),
    (N'380049', N'Ahmedabad', N'Gujarat', 3),
    (N'380050', N'Ahmedabad', N'Gujarat', 3),
    (N'380051', N'Ahmedabad', N'Gujarat', 3),
    (N'380052', N'Ahmedabad', N'Gujarat', 3),
    (N'380054', N'Ahmedabad', N'Gujarat', 3),
    (N'380055', N'Ahmedabad', N'Gujarat', 3),
    (N'380058', N'Ahmedabad', N'Gujarat', 3),
    (N'380059', N'Ahmedabad', N'Gujarat', 3),
    (N'380060', N'Ahmedabad', N'Gujarat', 3),
    (N'380061', N'Ahmedabad', N'Gujarat', 3),
    (N'380062', N'Ahmedabad', N'Gujarat', 3),
    (N'380063', N'Ahmedabad', N'Gujarat', 3),
    (N'382006', N'Ahmedabad', N'Gujarat', 4),
    (N'382010', N'Ahmedabad', N'Gujarat', 4),
    (N'382016', N'Ahmedabad', N'Gujarat', 4),
    (N'382024', N'Ahmedabad', N'Gujarat', 4),
    (N'382170', N'Ahmedabad', N'Gujarat', 4),
    (N'382210', N'Ahmedabad', N'Gujarat', 4),
    (N'382213', N'Ahmedabad', N'Gujarat', 4),
    (N'382330', N'Ahmedabad', N'Gujarat', 4),
    (N'382340', N'Ahmedabad', N'Gujarat', 4),
    (N'382345', N'Ahmedabad', N'Gujarat', 4),
    (N'382350', N'Ahmedabad', N'Gujarat', 4),
    (N'382415', N'Ahmedabad', N'Gujarat', 4),
    (N'382418', N'Ahmedabad', N'Gujarat', 4),
    (N'382421', N'Ahmedabad', N'Gujarat', 4),
    (N'382428', N'Ahmedabad', N'Gujarat', 4)
) AS src ([Pincode], [City], [State], [EstimatedDays])
ON tgt.[Pincode] = src.[Pincode]
WHEN MATCHED THEN UPDATE SET
    tgt.[City]          = src.[City],
    tgt.[State]         = src.[State],
    tgt.[EstimatedDays] = src.[EstimatedDays],
    tgt.[IsActive]      = 1,
    tgt.[UpdatedAt]     = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([Pincode], [City], [State], [EstimatedDays])
VALUES
    (src.[Pincode], src.[City], src.[State], src.[EstimatedDays]);
GO

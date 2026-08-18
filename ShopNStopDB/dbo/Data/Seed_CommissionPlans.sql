/*
  Seed default CommissionPlan rows. Idempotent — MERGE on PlanName.
*/

MERGE [dbo].[CommissionPlans] AS tgt
USING (VALUES
    (N'Default Platform Fee', NULL, 10.00, 0.00, NULL, 1.00, '2026-01-01', NULL, 1),
    (N'Apparel — Standard',   NULL,  8.00, 0.00, NULL, 1.00, '2026-01-01', NULL, 0),
    (N'Footwear — Standard',  NULL, 12.00, 0.00, NULL, 1.00, '2026-01-01', NULL, 0)
) AS src ([PlanName], [CategoryId], [CommissionRate], [MinFee], [MaxFee], [TdsRate],
         [EffectiveFrom], [EffectiveTo], [IsDefault])
   ON tgt.[PlanName] = src.[PlanName] AND tgt.[IsDeleted] = 0
WHEN NOT MATCHED THEN
    INSERT ([PlanName], [CategoryId], [CommissionRate], [MinFee], [MaxFee], [TdsRate],
            [EffectiveFrom], [EffectiveTo], [IsDefault])
    VALUES (src.[PlanName], src.[CategoryId], src.[CommissionRate], src.[MinFee], src.[MaxFee], src.[TdsRate],
            src.[EffectiveFrom], src.[EffectiveTo], src.[IsDefault]);
GO

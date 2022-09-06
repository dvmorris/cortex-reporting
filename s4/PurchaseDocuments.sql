(WITH
tcurx AS (
  -- Joining to this table is necesssary to fix the decimal place of
  -- amounts for non-decimal-based currencies. SAP stores these amounts
  -- offset by a factor  of 1/100 within the system (FYI this gets
  -- corrected when a user observes these in the GUI) Currencies w/
  -- decimals are unimpacted.
  --
  -- Example of impacted currencies JPY, IDR, KRW, TWD
  -- Example of non-impacted currencies USD, GBP, EUR
  -- Example 1,000 JPY will appear as 10.00 JPY
  SELECT DISTINCT
    CURRKEY,
    CAST(POWER(10, 2 - COALESCE(CURRDEC, 0)) AS NUMERIC) AS CURRFIX
  FROM
    `{{ project_id_src }}.{{ dataset_cdc_processed_s4 }}.tcurx`
),

conv AS (
  -- This table is used to convert rates from the transaction currency to USD.
  SELECT DISTINCT
    mandt,
    fcurr,
    tcurr,
    ukurs,
    PARSE_DATE("%Y%m%d", CAST(99999999 - CAST(gdatu AS INT64) AS STRING)) AS gdatu
  FROM `{{ project_id_src }}.{{ dataset_cdc_processed_s4 }}.tcurr`
  WHERE
    mandt = '{{ mandt_s4 }}'
    AND kurst = "M" -- Daily Corporate Rate
    AND tcurr {{ currency }} -- Convert to USD

  UNION ALL
## CORTEX-CUSTOMER: Replace with currency of choice, or add additional currencies
## as a union clause
  -- USD to USD rates do not exist in TCURR (or any other rates that are same-to-
  -- same such as EUR to EUR / JPY to JPY etc.
  SELECT
    '{{ mandt_s4 }}' AS mandt,
    "USD" AS fcurr,
    "USD" AS tcurr,
    1 AS ukurs,
    date_array AS gdatu
  FROM
    UNNEST(GENERATE_DATE_ARRAY("1990-01-01", "2060-12-31")) AS date_array
)

SELECT
  ekpo.MANDT AS Client_MANDT,
  ekpo.EBELN AS DocumentNumber_EBELN,
  ekpo.EBELP AS Item_EBELP,
  ekpo.LOEKZ AS DeletionFlag_LOEKZ,
  ekko.BUKRS AS Company_BUKRS,
  ekko.BSTYP AS DocumentCategory_BSTYP,
  ekko.BSART AS DocumentType_BSART,
  ekko.BSAKZ AS ControlFlag_BSAKZ,
  ekko.LOEKZ AS DeletionFlagHdr_LOEKZ,
  ekko.STATU AS Status_STATU,
  ekko.AEDAT AS CreatedOn_AEDAT,
  ekko.ERNAM AS CreatedBy_ERNAM,
  ekko.PINCR AS ItemNumberInterval_PINCR,
  ekko.LPONR AS LastItemNumber_LPONR,
  ekko.LIFNR AS VendorAccountNumber_LIFNR,
  ekko.SPRAS AS Language_SPRAS,
  ekko.ZTERM AS TermsPaymentKey_ZTERM,
  ekko.ZBD1T AS DiscountDays1_ZBD1T,
  ekko.ZBD2T AS DiscountDays2_ZBD2T,
  ekko.ZBD3T AS DiscountDays3_ZBD3T,
  ekko.ZBD1P AS CashDiscountPercentage1_ZBD1P,
  ekko.ZBD2P AS CashDiscountPercentage2_ZBD2P,
  ekko.EKORG AS PurchasingOrganization_EKORG,
  ekko.EKGRP AS PurchasingGroup_EKGRP,
  ekko.WAERS AS CurrencyKey_WAERS,
  ekko.WKURS AS ExchangeRate_WKURS,
  conv.UKURS AS ExchangeRateUSD_UKURS,
  ekko.KUFIX AS FlagFixingExchangeRate_KUFIX,
  ekko.BEDAT AS PurchasingDocumentDate_BEDAT,
  ekko.KDATB AS StartValidityPeriod_KDATB,
  ekko.KDATE AS EndValidityPeriod_KDATE,
  ekko.BWBDT AS ClosingDateforApplications_BWBDT,
  ekko.ANGDT AS Deadline_ANGDT,
  ekko.BNDDT AS BindingPeriodforQuotation_BNDDT,
  ekko.GWLDT AS WarrantyDate_GWLDT,
  ekko.AUSNR AS Bidinvitationnumber_AUSNR,
  ekko.ANGNR AS QuotationNumber_ANGNR,
  ekko.IHRAN AS QuotationSubmissionDate_IHRAN,
  ekko.IHREZ AS YourReference_IHREZ,
  ekko.VERKF AS VendorSalesperson_VERKF,
  ekko.TELF1 AS VendorTelephone_TELF1,
  ekko.LLIEF AS SupplyingVendor_LLIEF,
  ekko.KUNNR AS Customer_KUNNR,
  ekko.KONNR AS PrincipalPurchaseAgreement_KONNR,
  ekko.AUTLF AS CompleteDeliveryStipulated_AUTLF,
  ekko.WEAKT AS GoodsReceiptMsgFlag_WEAKT,
  ekko.RESWK AS SupplyTransportOrders_RESWK,
  ekko.KTWRT AS AreaPerDistributionValue_KTWRT,
  ekko.SUBMI AS CollectiveNumber_SUBMI,
  ekko.KNUMV AS Numberthedocumentcondition_KNUMV,
  ekko.KALSM AS Procedure_KALSM,
  ekko.STAFO AS UpdateGroupStatistics_STAFO,
  ekko.LIFRE AS DifferentInvoicingParty_LIFRE,
  ekko.EXNUM AS ForeignTradeDocument_EXNUM,
  ekko.UNSEZ AS OurReference_UNSEZ,
  ekko.LOGSY AS LogicalSystem_LOGSY,
  ekko.UPINC AS ItemNumberInterval_UPINC,
  ekko.STAKO AS TimeDependentConditions_STAKO,
  ekko.FRGGR AS Releasegroup_FRGGR,
  ekko.FRGSX AS ReleaseStrategy_FRGSX,
  ekko.FRGKE AS PurchasingDocumentRelease_FRGKE,
  ekko.FRGZU AS ReleaseStatus_FRGZU,
  ekko.FRGRL AS ReleaseIncomplete_FRGRL,
  ekko.LANDS AS CountryforTaxReturn_LANDS,
  ekko.LPHIS AS SchedulingAgreement_LPHIS,
  ekko.ADRNR AS Address_ADRNR,
  ekko.STCEG_L AS CountrySalesTaxIDNumber_STCEG_L,
  ekko.STCEG AS VATRegistrationNumber_STCEG,
  ekko.ABSGR AS ReasonforCancellation_ABSGR,
  ekko.ADDNR AS AdditionalDocument_ADDNR,
  ekko.KORNR AS CorrectionMiscProvisions_KORNR,
  ekko.MEMORY AS IncompleteFlag_MEMORY,
  ekko.PROCSTAT AS ProcessingState_PROCSTAT,
  ekko.RLWRT AS ValueAtRelease_RLWRT,
  ekko.REVNO AS VersionnumberinPurchasing_REVNO,
  ekko.SCMPROC AS SCMProcess_SCMPROC,
  ekko.REASON_CODE AS GoodsReceiptReason_REASON_CODE,
  ekko.MEMORYTYPE AS CategoryIncompleteness_MEMORYTYPE,
  ekko.RETTP AS RetentionFlag_RETTP,
  ekko.MSR_ID AS ProcessIdentificationNumber_MSR_ID,
  ekko.HIERARCHY_EXISTS AS PartaContractHierarchy_HIERARCHY_EXISTS,
  ekko.THRESHOLD_EXISTS AS ExchangeThresholdValue_THRESHOLD_EXISTS,
  ekko.LEGAL_CONTRACT AS LegalContractNumber_LEGAL_CONTRACT,
  ekko.DESCRIPTION AS ContractName_DESCRIPTION,
  ekko.RELEASE_DATE AS ReleaseDateContract_RELEASE_DATE,
  ekko.HANDOVERLOC AS Physicalhandover_HANDOVERLOC,
  ekko.FORCE_ID AS InternalKeyforForceElement_FORCE_ID,
  ekko.FORCE_CNT AS InternalCounter_FORCE_CNT,
  ekko.RELOC_ID AS RelocationID_RELOC_ID,
  ekko.RELOC_SEQ_ID AS RelocationStepID_RELOC_SEQ_ID,
  ekko.SOURCE_LOGSYS AS Logicalsystem_SOURCE_LOGSYS,
  ekko.VZSKZ AS InterestcalculationFlag_VZSKZ,
  ekko.POHF_TYPE AS SeasonalProcesingDocument_POHF_TYPE,
  ekko.EQ_EINDT AS SameDeliveryDate_EQ_EINDT,
  ekko.EQ_WERKS AS SameReceivingPlant_EQ_WERKS,
  ekko.FIXPO AS FirmDealFlag_FIXPO,
  ekko.EKGRP_ALLOW AS TakeAccountPurchGroup_EKGRP_ALLOW,
  ekko.WERKS_ALLOW AS TakeAccountPlants_WERKS_ALLOW,
  ekko.CONTRACT_ALLOW AS TakeAccountContracts_CONTRACT_ALLOW,
  ekko.PSTYP_ALLOW AS TakeAccountItemCategories_PSTYP_ALLOW,
  ekko.FIXPO_ALLOW AS TakeAccountFixedDate_FIXPO_ALLOW,
  ekko.KEY_ID_ALLOW AS ConsiderBudget_KEY_ID_ALLOW,
  ekko.AUREL_ALLOW AS TakeAccountAllocTableRelevance_AUREL_ALLOW,
  ekko.DELPER_ALLOW AS TakeAccountDlvyPeriod_DELPER_ALLOW,
  ekko.EINDT_ALLOW AS TakeAccountDeliveryDate_EINDT_ALLOW,
  ekko.LTSNR_ALLOW AS IncludeVendorSubrange_LTSNR_ALLOW,
  ekko.OTB_LEVEL AS OTBCheckLevel_OTB_LEVEL,
  ekko.OTB_COND_TYPE AS OTBConditionType_OTB_COND_TYPE,
  ekko.KEY_ID AS UniqueNumberBudget_KEY_ID,
  ekko.OTB_VALUE AS RequiredBudget_OTB_VALUE,
  ekko.OTB_CURR AS OTBCurrency_OTB_CURR,
  ekko.OTB_RES_VALUE AS ReservedBudgetforOTB_OTB_RES_VALUE,
  ekko.OTB_SPEC_VALUE AS SpecialReleaseBudget_OTB_SPEC_VALUE,
  ekko.BUDG_TYPE AS BudgetType_BUDG_TYPE,
  ekko.OTB_STATUS AS OTBCheckStatus_OTB_STATUS,
  ekko.OTB_REASON AS ReasonFlagforOTBCheckStatus_OTB_REASON,
  ekko.CHECK_TYPE AS TypeOTBCheck_CHECK_TYPE,
  ekko.CON_OTB_REQ AS OTBRelevantContract_CON_OTB_REQ,
  ekko.CON_PREBOOK_LEV AS OTBFlagLevelforContracts_CON_PREBOOK_LEV,
  ekko.CON_DISTR_LEV AS DistributionUsingTargetValueorItemData_CON_DISTR_LEV,
  ekpo.STATU AS RFQtatus_STATU,
  ekpo.AEDAT AS ChangeDate_AEDAT,
  ekpo.TXZ01 AS ShortText_TXZ01,
  ekpo.MATNR AS MaterialNumber_MATNR,
  ekpo.EMATN AS MaterialNumber_EMATN,
  ekpo.BUKRS AS CompanyCode_BUKRS,
  ekpo.WERKS AS Plant_WERKS,
  ekpo.LGORT AS StorageLocation_LGORT,
  ekpo.BEDNR AS RequirementTrackingNumber_BEDNR,
  ekpo.MATKL AS MaterialGroup_MATKL,
  ekpo.INFNR AS NumberofPurchasingInfoRecord_INFNR,
  ekpo.IDNLF AS MaterialNumberVendor_IDNLF,
  ekpo.KTMNG AS TargetQuantity_KTMNG,
  ekpo.MENGE AS POQuantity_MENGE,
  ekpo.MEINS AS UoM_MEINS,
  ekpo.BPRME AS OrderPriceUnit_BPRME,
  ekpo.BPUMZ AS OrderUnitNumerator_BPUMZ,
  ekpo.BPUMN AS OrderUnitDenominator_BPUMN,
  ekpo.UMREZ AS NumeratorforConversionofOrderUnittoBaseUnit_UMREZ,
  ekpo.UMREN AS DenominatorforConversionofOrderUnittoBaseUnit_UMREN,
  ekpo.PEINH AS PriceUnit_PEINH,
  ekpo.AGDAT AS DeadlineforSubmissionofBid_AGDAT,
  ekpo.WEBAZ AS GoodsReceiptProcessingTimeinDays_WEBAZ,
  ekpo.MWSKZ AS Taxcode_MWSKZ,
  ekpo.BONUS AS SettlementGroup1_BONUS,
  ekpo.INSMK AS StockType_INSMK,
  ekpo.SPINF AS UpdateInfoRecordFlag_SPINF,
  ekpo.PRSDR AS PricePrintout_PRSDR,
  ekpo.SCHPR AS EstimatedPriceFlag_SCHPR,
  ekpo.MAHNZ AS NumberofReminders_MAHNZ,
  ekpo.MAHN1 AS NumberofDaysforFirstReminder_MAHN1,
  ekpo.MAHN2 AS NumberofDaysforSecondReminder_MAHN2,
  ekpo.MAHN3 AS NumberofDaysforThirdReminder_MAHN3,
  ekpo.UEBTO AS OverdeliveryToleranceLimit_UEBTO,
  ekpo.UEBTK AS UnlimitedOverdeliveryAllowed_UEBTK,
  ekpo.UNTTO AS UnderdeliveryToleranceLimit_UNTTO,
  ekpo.BWTAR AS ValuationType_BWTAR,
  ekpo.BWTTY AS ValuationCategory_BWTTY,
  ekpo.ABSKZ AS RejectionFlag_ABSKZ,
  ekpo.AGMEM AS InternalCommentonQuotation_AGMEM,
  ekpo.ELIKZ AS DeliveryCompletedFlag_ELIKZ,
  ekpo.EREKZ AS FinalInvoiceFlag_EREKZ,
  ekpo.PSTYP AS ItemCategoryinPurchasingDocument_PSTYP,
  ekpo.KNTTP AS AccountAssignmentCategory_KNTTP,
  ekpo.KZVBR AS ConsumptionPosting_KZVBR,
  ekpo.VRTKZ AS DistributionFlagformultipleaccountassignment_VRTKZ,
  ekpo.TWRKZ AS PartialInvoiceFlag_TWRKZ,
  ekpo.WEPOS AS GoodsReceiptFlag_WEPOS,
  ekpo.WEUNB AS GoodsReceiptNonValuated_WEUNB,
  ekpo.REPOS AS InvoiceReceiptFlag_REPOS,
  ekpo.WEBRE AS FlagGRBasedInvoiceVerification_WEBRE,
  ekpo.KZABS AS OrderAcknowledgmentRequirement_KZABS,
  ekpo.LABNR AS OrderAcknowledgmentNumber_LABNR,
  ekpo.KONNR AS NumberofPrincipalPurchaseAgreement_KONNR,
  ekpo.KTPNR AS ItemNumberofPrincipalPurchaseAgreement_KTPNR,
  ekpo.ABDAT AS ReconciliationDateforAgreedCumulativeQuantity_ABDAT,
  ekpo.ABFTZ AS AgreedCumulativeQuantity_ABFTZ,
  ekpo.ETFZ1 AS FirmZone_ETFZ1,
  ekpo.ETFZ2 AS TradeOffZone_ETFZ2,
  ekpo.KZSTU AS FirmTradeOffZones_KZSTU,
  ekpo.NOTKZ AS ExclusioninOutlineAgreementItemwithMaterialClass_NOTKZ,
  ekpo.LMEIN AS BaseUnitofMeasure_LMEIN,
  ekpo.EVERS AS ShippingInstructions_EVERS,
  ekpo.NAVNW AS Nondeductibleinputtax_NAVNW,
  ekpo.ABMNG AS Standardreleaseorderquantity_ABMNG,
  ekpo.PRDAT AS DateofPriceDetermination_PRDAT,
  ekpo.BSTYP AS PurchasingDocumentCategory_BSTYP,
  ekpo.XOBLR AS Itemaffectscommitments_XOBLR,
  ekpo.ADRNR AS Manualaddressnumberinpurchasingdocumentitem_ADRNR,
  ekpo.EKKOL AS ConditionGroupwithVendor_EKKOL,
  ekpo.SKTOF AS ItemDoesNotQualifyforCashDiscount_SKTOF,
  ekpo.STAFO AS Updategroupforstatisticsupdate_STAFO,
  ekpo.PLIFZ AS PlannedDeliveryTimeinDays_PLIFZ,
  ekpo.NTGEW AS NetWeight_NTGEW,
  ekpo.GEWEI AS UnitofWeight_GEWEI,
  ekpo.TXJCD AS TaxJurisdiction_TXJCD,
  ekpo.ETDRK AS FlagPrintrelevantSchedulelinesexist_ETDRK,
  ekpo.SOBKZ AS SpecialStockFlag_SOBKZ,
  ekpo.ARSNR AS Settlementreservationnumber_ARSNR,
  ekpo.ARSPS AS Itemnumberofthesettlementreservation_ARSPS,
  ekpo.INSNC AS QualityinspectionFlagcannotbechanged_INSNC,
  ekpo.SSQSS AS ControlKeyforQualityManagementinProcurement_SSQSS,
  ekpo.ZGTYP AS CertificateType_ZGTYP,
  ekpo.EAN11 AS InternationalArticleNumber_EAN11,
  ekpo.BSTAE AS ConfirmationControlKey_BSTAE,
  ekpo.REVLV AS RevisionLevel_REVLV,
  ekpo.GEBER AS Fund_GEBER,
  ekpo.FISTL AS FundsCenter_FISTL,
  ekpo.FIPOS AS CommitmentItem_FIPOS,
  ekpo.KO_GSBER AS Businessareareportedtothepartner_KO_GSBER,
  ekpo.KO_PARGB AS assumedbusinessareaofthebusinesspartner_KO_PARGB,
  ekpo.KO_PRCTR AS ProfitCenter_KO_PRCTR,
  ekpo.KO_PPRCTR AS PartnerProfitCenter_KO_PPRCTR,
  ekpo.MEPRF AS PricingDateControl_MEPRF,
  ekpo.BRGEW AS GrossWeight_BRGEW,
  ekpo.VOLUM AS Volume_VOLUM,
  ekpo.VOLEH AS Volumeunit_VOLEH,
  ekpo.INCO1 AS Incoterms1_INCO1,
  ekpo.INCO2 AS Incoterms2_INCO2,
  ekpo.VORAB AS Advanceprocurement_VORAB,
  ekpo.KOLIF AS PriorVendor_KOLIF,
  ekpo.LTSNR AS VendorSubrange_LTSNR,
  ekpo.PACKNO AS Packagenumber_PACKNO,
  ekpo.FPLNR AS Invoicingplannumber_FPLNR,
  ekpo.STAPO AS Itemisstatistical_STAPO,
  ekpo.UEBPO AS HigherLevelIteminPurchasingDocuments_UEBPO,
  ekpo.LEWED AS LatestPossibleGoodsReceipt_LEWED,
  ekpo.EMLIF AS Vendortobesupplied_EMLIF,
  ekpo.LBLKZ AS Subcontractingvendor_LBLKZ,
  ekpo.SATNR AS CrossPlantConfigurableMaterial_SATNR,
  ekpo.ATTYP AS MaterialCategory_ATTYP,
  ekpo.VSART AS Shippingtype_VSART,
  ekpo.HANDOVERLOC AS Locationforaphysicalhandoverofgoods_HANDOVERLOC,
  ekpo.KANBA AS KanbanFlag_KANBA,
  ekpo.ADRN2 AS Numberofdeliveryaddress_ADRN2,
  ekpo.CUOBJ AS internalObjectNumber_CUOBJ,
  ekpo.XERSY AS EvaluatedReceiptSettlement_XERSY,
  ekpo.EILDT AS StartDateforGRBasedSettlement_EILDT,
  ekpo.DRDAT AS LastTransmission_DRDAT,
  ekpo.DRUHR AS Time_DRUHR,
  ekpo.DRUNR AS SequentialNumber_DRUNR,
  ekpo.AKTNR AS Promotion_AKTNR,
  ekpo.ABELN AS AllocationTableNumber_ABELN,
  ekpo.ABELP AS Itemnumberofallocationtable_ABELP,
  ekpo.ANZPU AS NumberofPoints_ANZPU,
  ekpo.PUNEI AS Pointsunit_PUNEI,
  ekpo.SAISO AS SeasonCategory_SAISO,
  ekpo.SAISJ AS SeasonYear_SAISJ,
  ekpo.EBON2 AS SettlementGroup2_EBON2,
  ekpo.EBON3 AS SettlementGroup3_EBON3,
  ekpo.EBONF AS ItemRelevanttoSubsequentSettlement_EBONF,
  ekpo.MLMAA AS Materialledgeractivatedatmateriallevel_MLMAA,
  ekpo.MHDRZ AS MinimumRemainingShelfLife_MHDRZ,
  ekpo.ANFNR AS RFQNumber_ANFNR,
  ekpo.ANFPS AS ItemNumberofRFQ_ANFPS,
  ekpo.KZKFG AS OriginofConfiguration_KZKFG,
  ekpo.USEQU AS Quotaarrangementusage_USEQU,
  ekpo.UMSOK AS SpecialStockFlagforPhysicalStockTransfer_UMSOK,
  ekpo.BANFN AS PurchaseRequisitionNumber_BANFN,
  ekpo.BNFPO AS ItemNumberofPurchaseRequisition_BNFPO,
  ekpo.MTART AS MaterialType_MTART,
  ekpo.UPTYP AS SubitemCategory_UPTYP,
  ekpo.UPVOR AS SubitemsExist_UPVOR,
  ekpo.KZWI1 AS Subtotal1frompricingprocedureforcondition_KZWI1,
  ekpo.KZWI2 AS Subtotal2frompricingprocedureforcondition_KZWI2,
  ekpo.KZWI3 AS Subtotal3frompricingprocedureforcondition_KZWI3,
  ekpo.KZWI4 AS Subtotal4frompricingprocedureforcondition_KZWI4,
  ekpo.KZWI5 AS Subtotal5frompricingprocedureforcondition_KZWI5,
  ekpo.KZWI6 AS Subtotal6frompricingprocedureforcondition_KZWI6,
  ekpo.SIKGR AS Processingkeyforsubitems_SIKGR,
  ekpo.MFZHI AS MaximumCumulativeMaterialGoAheadQuantity_MFZHI,
  ekpo.FFZHI AS MaximumCumulativeProductionGoAheadQuantity_FFZHI,
  ekpo.RETPO AS ReturnsItem_RETPO,
  ekpo.AUREL AS RelevanttoAllocationTable_AUREL,
  ekpo.BSGRU AS ReasonforOrdering_BSGRU,
  ekpo.LFRET AS DeliveryTypeforReturnstoVendors_LFRET,
  ekpo.MFRGR AS Materialfreightgroup_MFRGR,
  ekpo.NRFHG AS Materialqualifiesfordiscountinkind_NRFHG,
  ekpo.ABUEB AS ReleaseCreationProfile_ABUEB,
  ekpo.NLABD AS NextForecastDeliveryScheduleTransmission_NLABD,
  ekpo.NFABD AS NextJITDeliveryScheduleTransmission_NFABD,
  ekpo.KZBWS AS ValuationofSpecialStock_KZBWS,
  ekpo.FABKZ AS FlagItemRelevanttoJITDeliverySchedules_FABKZ,
  ekpo.J_1AINDXP AS InflationIndex_J_1AINDXP,
  ekpo.J_1AIDATEP AS InflationIndexDate_J_1AIDATEP,
  ekpo.MPROF AS ManufacturerPartProfile_MPROF,
  ekpo.EGLKZ AS OutwardDeliveryCompletedFlag_EGLKZ,
  ekpo.KZTLF AS StockTransfer_KZTLF,
  ekpo.KZFME AS Unitsofmeasureusage_KZFME,
  ekpo.RDPRF AS RoundingProfile_RDPRF,
  ekpo.TECHS AS StandardVariant_TECHS,
  ekpo.CHG_SRV AS Configurationchanged_CHG_SRV,
  ekpo.CHG_FPLNR AS Noinvoiceforthisitemalthoughnotfreeofcharge_CHG_FPLNR,
  ekpo.MFRPN AS ManufacturerPartNumber_MFRPN,
  ekpo.MFRNR AS NumberofaManufacturer_MFRNR,
  ekpo.EMNFR AS Externalmanufacturercodenameornumber_EMNFR,
  ekpo.NOVET AS ItemblockedforSDdelivery_NOVET,
  ekpo.AFNAM AS NameofRequester_AFNAM,
  ekpo.TZONRC AS Timezoneofrecipientlocation_TZONRC,
  ekpo.IPRKZ AS PeriodFlagforShelfLifeExpirationDate_IPRKZ,
  ekpo.LEBRE AS FlagforServiceBasedInvoiceVerification_LEBRE,
  ekpo.BERID AS MRPArea_BERID,
  ekpo.XCONDITIONS AS Conditionsforitemalthoughnoinvoice_XCONDITIONS,
  ekpo.APOMS AS APOasPlanningSystem_APOMS,
  ekpo.CCOMP AS PostingLogicintheCaseofStockTransfers_CCOMP,
  ekpo.GRANT_NBR AS Grant_GRANT_NBR,
  ekpo.FKBER AS FunctionalArea_FKBER,
  ekpo.STATUS AS StatusofPurchasingDocumentItem_STATUS,
  ekpo.RESLO AS IssuingStorageLocationforStockTransportOrder_RESLO,
  ekpo.KBLNR AS DocumentNumberforEarmarkedFunds_KBLNR,
  ekpo.KBLPOS AS EarmarkedFundsDocumentItem_KBLPOS,
  ekpo.WEORA AS AcceptanceAtOrigin_WEORA,
  ekpo.SRV_BAS_COM AS ServiceBasedCommitment_SRV_BAS_COM,
  ekpo.PRIO_URG AS RequirementUrgency_PRIO_URG,
  ekpo.PRIO_REQ AS RequirementPriority_PRIO_REQ,
  ekpo.EMPST AS Receivingpoint_EMPST,
  ekpo.DIFF_INVOICE AS DifferentialInvoicing_DIFF_INVOICE,
  ekpo.TRMRISK_RELEVANT AS RiskRelevancyinPurchasing_TRMRISK_RELEVANT,
  ekpo.SPE_ABGRU AS Reasonforrejectionofquotationsandsalesorders_SPE_ABGRU,
  ekpo.SPE_CRM_SO AS CRMSalesOrderNumberforTPOP_SPE_CRM_SO,
  ekpo.SPE_CRM_SO_ITEM AS CRMSalesOrderItemNumberinTPOP_SPE_CRM_SO_ITEM,
  ekpo.SPE_CRM_REF_SO AS CRMReferenceOrderNumberforTPOP_SPE_CRM_REF_SO,
  ekpo.SPE_CRM_REF_ITEM AS CRMReferenceSalesOrderItemNumberinTPOP_SPE_CRM_REF_ITEM,
  ekpo.SPE_CRM_FKREL AS BillingRelevanceCRM_SPE_CRM_FKREL,
  ekpo.SPE_CHNG_SYS AS LastChangerSystemType_SPE_CHNG_SYS,
  ekpo.SPE_INSMK_SRC AS StockTypeofSourceStorageLocationinSTO_SPE_INSMK_SRC,
  ekpo.SPE_CQ_CTRLTYPE AS CQControlType_SPE_CQ_CTRLTYPE,
  ekpo.SPE_CQ_NOCQ AS NoTransmissionofCumulativeQuantitiesinSARelease_SPE_CQ_NOCQ,
  ekpo.REASON_CODE AS GoodsReceiptReasonCode_REASON_CODE,
  ekpo.CQU_SAR AS CumulativeGoodsReceipts_CQU_SAR,
  ekpo.ANZSN AS Numberofserialnumbers_ANZSN,
  ekpo.SPE_EWM_DTC AS EWMDeliveryBasedToleranceCheck_SPE_EWM_DTC,
  ekpo.EXLIN AS ItemNumberLength_EXLIN,
  ekpo.EXSNR AS ExternalSorting_EXSNR,
  ekpo.EHTYP AS ExternalHierarchyCategory_EHTYP,
  ekpo.RETPC AS RetentioninPercent_RETPC,
  ekpo.DPTYP AS DownPaymentFlag_DPTYP,
  ekpo.DPPCT AS DownPaymentPercentage_DPPCT,
  ekpo.DPAMT AS DownPaymentinDocumentCurrency_DPAMT,
  ekpo.DPDAT AS DueDateforDownPayment_DPDAT,
  ekpo.FLS_RSTO AS StoreReturnwithInboundandOutboundDelivery_FLS_RSTO,
  ekpo.EXT_RFX_NUMBER AS DocumentNumberofExternalDocument_EXT_RFX_NUMBER,
  ekpo.EXT_RFX_ITEM AS ItemNumberofExternalDocument_EXT_RFX_ITEM,
  ekpo.EXT_RFX_SYSTEM AS LogicalSystem_EXT_RFX_SYSTEM,
  ekpo.SRM_CONTRACT_ID AS CentralContract_SRM_CONTRACT_ID,
  ekpo.SRM_CONTRACT_ITM AS CentralContractItemNumber_SRM_CONTRACT_ITM,
  ekpo.BLK_REASON_ID AS BlockingReasonID_BLK_REASON_ID,
  ekpo.BLK_REASON_TXT AS BlockingReasonText_BLK_REASON_TXT,
  ekpo.ITCONS AS RealTimeConsumptionPostingofSubcontractingComponents_ITCONS,
  ekpo.FIXMG AS DeliveryDateandQuantityFixed_FIXMG,
  ekpo.WABWE AS FlagforGIbasedgoodsreceipt_WABWE,
  ekpo.TC_AUT_DET AS TaxCodeAutomaticallyDetermined_TC_AUT_DET,
  ekpo.MANUAL_TC_REASON AS ManualTaxCodeReason_MANUAL_TC_REASON,
  ekpo.FISCAL_INCENTIVE AS TaxIncentiveType_FISCAL_INCENTIVE,
  ekpo.TAX_SUBJECT_ST AS TaxSubject_TAX_SUBJECT_ST,
  ekpo.FISCAL_INCENTIVE_ID AS IncentiveID_FISCAL_INCENTIVE_ID,
  ekpo.ADVCODE AS AdviceCode_ADVCODE,
  ekpo.BUDGET_PD AS FMBudgetPeriod_BUDGET_PD,
  ekpo.EXCPE AS AcceptancePeriod_EXCPE,
  ekpo.IUID_RELEVANT AS IUIDRelevant_IUID_RELEVANT,
  ekpo.MRPIND AS RetailPriceRelevant_MRPIND,
  ekpo.REFSITE AS ReferenceSiteForPurchasing_REFSITE,
  ekpo.SERRU AS Typeofsubcontracting_SERRU,
  ekpo.SERNP AS SerialNumberProfile_SERNP,
  ekpo.DISUB_SOBKZ AS SpecialstockFlagSubcontracting_DISUB_SOBKZ,
  ekpo.DISUB_PSPNR AS WBSElement_DISUB_PSPNR,
  ekpo.DISUB_KUNNR AS CustomerNumber_DISUB_KUNNR,
  ekpo.DISUB_VBELN AS SalesandDistributionDocumentNumber_DISUB_VBELN,
  ekpo.DISUB_POSNR AS ItemnumberoftheSDdocument_DISUB_POSNR,
  ekpo.DISUB_OWNER AS Ownerofstock_DISUB_OWNER,
  ekpo.REF_ITEM AS ReferenceItemforRemainingQtyCancellation_REF_ITEM,
  ekpo.SOURCE_ID AS OriginProfile_SOURCE_ID,
  ekpo.SOURCE_KEY AS KeyinSourceSystem_SOURCE_KEY,
  ekpo.PUT_BACK AS FlagforPuttingBackfromGroupedPODocument_PUT_BACK,
  ekpo.POL_ID AS OrderListItemNumber_POL_ID,
  ekpo.CONS_ORDER AS PurchaseOrderforConsignment_CONS_ORDER,
  COALESCE(ekpo.NETPR * tcurx.CURRFIX, ekpo.NETPR) AS NetPrice_NETPR,
  COALESCE(ekpo.NETPR * tcurx.CURRFIX, ekpo.NETPR) * conv.UKURS AS NetPriceUSD_NETPR,
  COALESCE(ekpo.NETWR * tcurx.CURRFIX, ekpo.NETWR) AS NetOrderValueinPOCurrency_NETWR,
  COALESCE(ekpo.BRTWR * tcurx.CURRFIX, ekpo.BRTWR) AS GrossOrderValueinPOcurrency_BRTWR,
  COALESCE(ekpo.NETWR * tcurx.CURRFIX, ekpo.NETWR) * conv.UKURS AS NetOrderValueinPOCurrencyUSD_NETWR,
  COALESCE(ekpo.BRTWR * tcurx.CURRFIX, ekpo.BRTWR) * conv.UKURS AS GrossOrderValueinPOcurrencyUSD_BRTWR,
  COALESCE(ekpo.ZWERT * tcurx.currfix, ekpo.ZWERT) AS TargetValueforOutlineAgreementinDocumentCurrency_ZWERT,
  COALESCE(ekpo.ZWERT * tcurx.currfix, ekpo.ZWERT) * conv.UKURS AS TargetValueforOutlineAgreementinDocumentCurrencyUSD_ZWERT,
  COALESCE(ekpo.EFFWR * tcurx.CURRFIX, ekpo.EFFWR) AS Effectivevalueofitem_EFFWR,
  COALESCE(ekpo.EFFWR * tcurx.CURRFIX, ekpo.EFFWR) * conv.UKURS AS EffectivevalueofitemUSD_EFFWR,
  COALESCE(ekpo.GNETWR, tcurx.CURRFIX, ekpo.GNETWR) AS Currentlynotused_GNETWR,
  COALESCE(ekpo.BONBA * tcurx.currfix, ekpo.BONBA) AS Rebatebasis1_BONBA
FROM `{{ project_id_src }}.{{ dataset_cdc_processed_s4 }}.ekko` AS ekko
INNER JOIN `{{ project_id_src }}.{{ dataset_cdc_processed_s4 }}.ekpo` AS ekpo
  ON ekko.MANDT = ekpo.mandt AND ekko.EBELN = ekpo.ebeln
LEFT JOIN tcurx
  ON ekko.WAERS = tcurx.CURRKEY
LEFT JOIN conv
  ON ekko.MANDT = conv.MANDT
    AND ekko.WAERS = conv.FCURR
    AND CAST(ekko.aedat AS DATE) = conv.GDATU
)

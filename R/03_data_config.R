############################################################################# #
# 03_data_config.R
#
# Purpose:
#   Central dataset structure and variable mappings for the 4 imported datasets,
#   in lists:
#       * CONFIG_ESM
#       * CONFIG_BG
#       * CONFIG_VMR
#       * CONFIG_POST
#   These lists can be unpacked in other scripts when needed, so the columns 
#   and variables can be directly referred to.

# Usage:
#   Run source("R/03_data_config.R")
#   Sourcing is included in R/00_setup.R together with R/01_paths.R, 
#   R/02_packages.R, and R/04_functions.R
#
############################################################################## #

## ########################################################################### #
# ---- 1. ESM configuration ---------------------------------------------------- 
## ########################################################################### #

CONFIG_ESM <- list(
  # Columns mapping from codebook
  cols = list(
    dyad         = "CoupleID",              # Couple ID number
    person       = "PpID",                  # Participant ID number
    part_no      = "partner_no",            # Partner number
    gen_com      = "GeneralComments",       # General comments provided by participant or researcher 
    ESM_com      = "ESMComments",           # ESM comments provided by participant or researcher 
    beep         = "beepno",                # beepnumber
    ts_sched     = "timeStampScheduled",    # time stamp the notification was scheduled for
    ts_sent      = "timeStampSent",         # time stamp the notification was sent
    ts_start     = "timeStampStart",        # time stamp the interaction started (questionnaire was opened)
    ts_stop      = "timeStampStop",         # time stamp the interaction was completed (questionnaire was finished)
    ots_sent     = "originalTimeStampSent", # in case of reminders, time stamp of the original interaction
    compl        = "compliance",            # proportion complete beeps / number of beeps in dataset (per participant)
    start        = "started",               # whether a beep was started
    end          = "complete"               # whether a beep was completed (based on non-conditional items)
  ),
  # Variables mapping from codebook
  vars = list(
    anger        = "angry",               # Anger
    stress       = "stress",              # Stress
    sad          = "sad",                 # Sadness
    NA_own       = "NA_own",              # Own negative affect
    PA_own       = "PA_own",              # Own positive affect
    anhed        = "anhedonia",           # Anhedonia
    fat          = "tired",               # Fatigue
    insec        = "insecure",            # Insecurity
    part_pres    = "partner_presence",    # Partner presence
    part_cont    = "partner_contact",     # Contact with partner
    neg_part     = "negevent_partner",    # Unpleasant moment with partner
    pos_part     = "posevent_partner",    # Enjoyable moment with partner
    reass_own    = "reassurance_own",     # own reassurance seeking
    IER          = "extrinsicIER",        # Extrinsic interpersonal emotion regulation
    expr_own     = "expression_own",      # Emotion expression
    agency_own   = "dominance_own",       # Own agency/dominance
    comm_own     = "affiliation_own",     # Own communion/affiliation    
    reass_part   = "reassurance_partner", # perceived partner reassurance seeking
    expr_part    = "expression_partner",  # Emotion expression (perceived)
    agency_part  = "dominance_partner",   # Partner agency/dominance
    comm_part    = "affiliation_partner", # Partner communion/affiliation    
    pres_oth     = "presence_others",     # Presence of others
    cont_oth     = "contact_others",      # Contact with others
    neg_gen      = "negevent_general",    # Negative event general
    pos_gen      = "posevent_general",    # Positive event general
    lonely       = "lonely",              # Loneliness
    rumin        = "rumination",          # Rumination about relationship
    posthoughts  = "posthoughts",         # Positive reminiscence about relationship
    expr_des     = "expression_desire",   # Emotion expression desire
    aff_des      = "affection_desire",    # Affection desire
    sex_des_own  = "sexualdesire_own",    # Sexual desire
    love         = "loving",              # Loving towards partner
    PA_part_perc = "PA_partner",          # Perceived partner positive affect
    NA_part_perc = "NA_partner",          # Perceived partner negative affect    
    perc_resp    = "perc_respons",        # Perceived partner responsiveness
    press        = "pressure",            # Pressure not to feel sad or stressed
    sex_des_part = "sexualdesire_partner" # Perceived desire partner
  ),
  # Valid Ranges (Min, Max) for each variable
  ranges = list(
    limits_anger         = c(0, 100),
    limits_stress        = c(0, 100),
    limits_sad           = c(0, 100),
    limits_NA_own        = c(0, 100),
    limits_PA_own        = c(0, 100),
    limits_anhed         = c(0, 100),
    limits_fat           = c(0, 100),
    limits_insec         = c(0, 100),
    limits_part_pres     = c(0, 1),       # 0=No, 1=Yes
    limits_part_cont     = c(1, 4),       # 1=No contact, 2-4=Types of contact
    limits_neg_part      = c(1, 3),
    limits_pos_part      = c(1, 3),
    limits_reass_own     = c(0, 100),
    limits_IER           = c(-50, 50),
    limits_expr_own      = c(1, 4),
    limits_agency_own    = c(-3, 3),
    limits_comm_own      = c(-3, 3),
    limits_reass_part    = c(0, 100),
    limits_expr_part     = c(1, 4),
    limits_agency_part   = c(-3, 3),
    limits_comm_part     = c(-3, 3),
    limits_pres_oth      = c(1, 7),       # 7 = No, 1-6 = Types of others
    limits_cont_oth      = c(1, 7),       # 7 = No, 1-6 = Types of others
    limits_neg_gen       = c(1, 3),
    limits_pos_gen       = c(1, 3),
    limits_lonely        = c(0, 100),
    limits_rumin         = c(0, 100),
    limits_posthoughts   = c(0, 100),
    limits_expr_des      = c(1, 4),
    limits_aff_des       = c(0, 100),
    limits_sex_des_own   = c(0, 100),
    limits_love          = c(0, 100),
    limits_PA_part_perc  = c(0, 100),
    limits_NA_part_perc  = c(0, 100),
    limits_perc_resp     = c(0, 100),
    limits_press         = c(0, 100),
    limits_sex_des_part  = c(0, 100)
  ),
  # List of specific variables for targeted missingness or conditional items checks
  groups = list(
    # group with timestamp data
    vars_time = c("timeStampScheduled", "timeStampSent", "timeStampStart", "timeStampStop"),
    # group core to the present research
    vars_core = c('NA_own', 'PA_own', 'NA_partner', 'PA_partner', 
                    'loving', 'perc_respons', 'negevent_partner', 'posevent_partner'),
    # group with conditional items
    vars_branch_partner = c(
      "negevent_partner", "posevent_partner", "reassurance_own", "extrinsicIER", 
      "expression_own", "dominance_own", "affiliation_own", "reassurance_partner", 
      "expression_partner", "dominance_partner", "affiliation_partner"),
    # group with conditional items
    vars_branch_no_partner = c(
      "presence_others", "contact_others", "negevent_general", "posevent_general", 
      "lonely", "rumination", "posthoughts", "expression_desire", "affection_desire")
  )
)

## ########################################################################### #
# ---- 2. BG configuration ---------------------------------------------------- 
## ########################################################################### #

CONFIG_BG <- list(
  # Columns mapping
  cols = list(
    person  = "PpID",
    dyad    = "CoupleID",
    age     = "AgeYEARS",
    gender  = "gender",
    nat     = "nationality",
    etn     = "etnicity",
    edu     = "edu",
    child   = "childrenYN",
    liv_tog = "livingTogether",
    rel_dur = "RelDurMonths",
    med     = "medication_none" # NA = no, 1=yes
  ),
  # Mapping of column values to their labels
  value_labels = list(
    gender  = c("1" = "Male", "2" = "Female", "3" = "Other"),
    nat     = c("4" = "Belgian", "5" = "Dutch", "6" = "Other"),
    etn     = c("1" = "Asian", "2" = "Black or AFrican-American", 
                    "3" = "Spanish or Latino", "4" = "White", "5" = "Other"),
    edu     = c("1" = "Primary School", "2" = "High School", 
                    "3" = "Bachelor", "4" = "Master", "5" = "PhD"),
    child   = c("0" = "No", "1" = "Yes"),
    liv_tog = c("1" = "No", "2" = "Yes"),
    med     = c("0" = "Not Medicated", "1" = "Medicated") # NA = no, 1=yes
  ),
  # Lists of scale items for range checks
  scales = list(
    scale_NSF           = paste0("NSF", 1:16),    # Need Satisfaction & Frustration
    scale_CESD          = paste0("CESD", 1:20),   # Depressive syptoms     
    scale_DCI           = paste0("DCI", 1:30),    # Dyadic coping
    scale_ECR           = paste0("ECR", 1:12),    # Attachment 
    scale_EROS          = paste0("EROS", 1:9),    # Emotion Regulation Others and Self
    scale_IDSSR         = paste0("IDSSR", 1:30),  # Depressive Symptoms      
    scale_PAQ           = paste0("PAQ", 1:16),    # Problem Areas in relationships
    scale_PRQCI         = paste0("PRQCI", 1:18),  # Perceived Relationship Quality   
    scale_QSI6          = paste0("QSI6", 1:12),   # Sexual Satisfaction
    scale_ROES          = paste0("ROES", 1:32),   # Interpersonal emotion regulation  
    scale_RRS           = paste0("RRS", 1:26),    # Reflection and Rumination
    scale_RSE           = paste0("RSE", 1:10),    # Self Esteem
    scale_SIS           = paste0("SIS", 1:14),    # Sexual Inhibition 
    scale_SWLS          = paste0("SWLS", 1:5),    # Satisfaction With Life Scale
    scale_ADPIV1        = paste0("ADPIV1.", 1:10),# Borderline Symptoms
    scale_ADPIV2        = paste0("ADPIV2.", 1:10),# Borderline Symptoms     
    scale_CSIV          = paste0("CSIV", 1:32),   # Interpersonal Values
    scale_DIRIRS        = paste0("DIRIRS", 1:4),  # Reinsurance seeking
    scale_WHODAS_likert = paste0("WHODAS", 1:12), # General Functioning
    scale_WHODAS_days   = paste0("WHODAS", 13:15) # General Functioning
  ),
  # items to be reversed (NOT EXHAUSTIVE, only for DCI, add if needed)
  reverse_items = list(
    DCI_reverse_items = c(7, 10, 11, 15, 22, 25, 26, 27)
  ),
  # Valid Ranges (Min, Max) for each scale
  ranges = list(
    limits_NSF           = c(1, 5),      
    limits_CESD          = c(0, 3),   
    limits_DCI           = c(1, 5),    
    limits_ECR           = c(1, 7),    
    limits_EROS          = c(1, 5),    
    limits_IDSSR         = c(0, 3),   
    limits_PAQ           = c(1, 7),    
    limits_PRQCI         = c(1, 7),  
    limits_QSI6          = c(1, 6),   
    limits_ROES          = c(1, 6),   
    limits_RRS           = c(1, 4),    
    limits_RSE           = c(0, 3),    
    limits_SIS           = c(1, 4),    
    limits_SWLS          = c(1, 7),    
    limits_WHODAS        = c(1, 5), 
    limits_ADPIV1        = c(1, 7),
    limits_ADPIV2        = c(1, 3),
    limits_CSIV          = c(1, 5),   
    limits_DIRIRS        = c(1, 7),
    limits_WHODAS_likert = c(1, 5), 
    limits_WHODAS_days   = c(0, 30)  # Days range
  ),
  groups = list(
    # group with timestamp data
    vars_time = c("StartQ", "EndQ"),
    # group core to the present research
    vars_core = paste0("DCI", 1:30)
  ),
  settings = list(
    min_age = 18,
    max_age = 65 # max in codebook
  )
)

## ########################################################################### #
# ---- 3. VMR configuration ---------------------------------------------------- 
## ########################################################################### #

CONFIG_VMR <- list(
  # Columns mapping from codebook
  cols = list(
    dyad        = "CoupleID",
    person      = "PpID",
    topic       = "topic",
    segment     = "timepoint",
    duration    = "duration_minutes"
  ),
  # Variables mapping from codebook
  vars = list(
    NA_own      = "neg_aff_own",        # Own negative affect
    NA_part_perc= "neg_aff_partner",    # Perceived partner negative affect    
    PA_own      = "pos_aff_own",        # Own positive affect
    PA_part_perc= "pos_aff_partner",    # Perceived partner positive affect
    press       = "press_sad",          # Pressure not to feel sad or stressed
    reass_part  = "perc_reassk",        # Perceived partner reassurance seeking
    suppression = "suppression",        # Own suppression
    IER         = "extr_IER",           # Extrinsic interpersonal emotion regulation
    agency_own  = "own_agency",         # Own agency
    agency_part = "partner_agency",     # Partner agency
    comm_own    = "own_communion",      # Own communion
    comm_part   = "partner_communion"   # Partner communion
  ),
  # Valid Ranges (Min, Max) for each variable
  ranges = list(
    limits_NA_own      = c(0, 100),
    limits_NA_part_perc= c(0, 100),
    limits_PA_own      = c(0, 100),
    limits_PA_part_perc= c(0, 100),
    limits_press       = c(0, 100),
    limits_reass_part  = c(0, 100),
    limits_suppression = c(0, 100),
    limits_IER         = c(0, 100),
    limits_agency_own  = c(-3, 3),
    limits_agency_part = c(-3, 3),
    limits_comm_own    = c(-3, 3),
    limits_comm_part   = c(-3, 3)
  ),
  # List of specific variables for targeted checks
  groups = list(
    # group core to the present research
    vars_core = c('neg_aff_own', 'pos_aff_own', 'neg_aff_partner', 'pos_aff_partner')
  )
)

## ########################################################################### #
# ---- 4. POST configuration --------------------------------------------------- 
## ########################################################################### #
CONFIG_POST <- list(
  # Columns mapping from codebook
  cols = list(
    dyad     = "CoupleID",
    person   = "PpID",
    start    = "StartDate", # date and time questionnaire was started by participant
    end      = "EndDate",   # date and time questionnaire was completed by participant
    duration = "Duration"   # duration to complete in seconds
  ),
  # Variables mapping from codebook
  vars = list(
    # Negative interaction items
    anger_neg            = "Anger_neg",
    stress_neg           = "Stress_neg",
    sad_neg              = "Sad_neg",
    happy_neg            = "Happy_neg",
    love_neg             = "Lovingly_neg",
    close_neg            = "Close_neg",
    ignored_neg          = "Ignored_neg",
    irritated_neg        = "Irritated_neg",
    hurt_neg             = "Hurt_neg",
    guilt_neg            = "Guilt_neg",
    indifferent_neg      = "Indifferent_neg",
    emo_connected_neg    = "EmoConnected_neg",
    emo_match_neg        = "EmoMatch_neg",
    s_care_about_p_neg   = "SCareAboutP_neg", # Self Care About Partnet
    p_care_about_s_neg   = "PCareAboutS_neg", # Partner Care ABout Self
    p_free_neg           = "Pfree_neg",
    s_free_neg           = "Sfree_neg",
    satisfied_conv_neg   = "SatisfiedWConversation_neg",
    representive_neg     = "Representive_neg",
    # Positive interaction items
    anger_pos            = "Anger_pos",
    stress_pos           = "Stress_pos",
    sad_pos              = "Sad_pos",
    happy_pos            = "Happy_pos",
    love_pos             = "Lovingly_pos",
    close_pos            = "Close_pos",
    ignored_pos          = "Ignored_pos",
    irritated_pos        = "Irritated_pos",
    hurt_pos             = "Hurt_pos",
    guilt_pos            = "Guilt_pos",
    indifferent_pos      = "Indifferent_pos",
    emo_connected_pos    = "EmoConnected_pos",
    emo_match_pos        = "EmoMatch_pos",
    s_care_about_p_pos   = "SCareAboutP_pos",
    p_care_about_s_pos   = "PCareAboutS_pos",
    p_free_pos           = "Pfree_pos",
    s_free_pos           = "Sfree_pos",
    satisfied_conv_pos   = "SatisfiedWConversation_pos",
    representive_pos     = "Representive_pos"
  ), 
  # Valid Ranges (Min, Max) for each variable
  ranges = list(
    limits_anger_neg             = c(0, 100),
    limits_stress_neg            = c(0, 100),
    limits_sad_neg               = c(0, 100),
    limits_happy_neg             = c(0, 100),
    limits_love_neg              = c(0, 100),
    limits_close_neg             = c(0, 100),
    limits_ignored_neg           = c(0, 100),
    limits_irritated_neg         = c(0, 100),
    limits_hurt_neg              = c(0, 100),
    limits_guilt_neg             = c(0, 100),
    limits_indifferent_neg       = c(0, 100),
    limits_emo_connected_neg     = c(0, 100),
    limits_emo_match_neg         = c(0, 5),
    limits_s_care_about_p_neg    = c(0, 6),
    limits_p_care_about_s_neg    = c(0, 6),
    limits_p_free_neg            = c(0, 6),
    limits_s_free_neg            = c(0, 6),
    limits_satisfied_conv_neg    = c(1, 7),
    limits_representive_neg      = c(1, 7),
    limits_anger_pos             = c(0, 100),
    limits_stress_pos            = c(0, 100),
    limits_sad_pos               = c(0, 100),
    limits_happy_pos             = c(0, 100),
    limits_love_pos              = c(0, 100),
    limits_close_pos             = c(0, 100),
    limits_ignored_pos           = c(0, 100),
    limits_irritated_pos         = c(0, 100),
    limits_hurt_pos              = c(0, 100),
    limits_guilt_pos             = c(0, 100),
    limits_indifferent_pos       = c(0, 100),
    limits_emo_connected_pos     = c(0, 100),
    limits_emo_match_pos         = c(0, 5),
    limits_s_care_about_p_pos    = c(0, 6),
    limits_p_care_about_s_pos    = c(0, 6),
    limits_p_free_pos            = c(0, 6),
    limits_s_free_pos            = c(0, 6),
    limits_satisfied_conv_pos    = c(1, 7),
    limits_representive_pos      = c(1, 7)
  ),
  groups = list(
    # group core to the present research
    vars_core = c("Lovingly_neg", "Lovingly_pos", "Close_neg", "Close_pos")
  )
)
############################################################################# #
# 03_data_config.R
#
# Purpose:
# Central dataset structure and variable mappings for the 4 imported datasets,
# in lists:
#       * CONFIG_ESM
#       * CONFIG_BG
#       * CONFIG_VMR
#       * CONFIG_POST
# These lists can be unpacked in other scripts when needed, so the columns 
# and variables can be directly referred to.

# Usage:
# Run source("R/02_structure_checks.R") to see the report without code echoing.
# Assumes data is located in dir_data, afer running 01_data_import.R at least once
#       * data/imported/esm_raw.rds
#       * data/imported/esm_bg.rds
#       * data/imported/esm_vmr.rds
#       * data/imported/esm_post.rds
# Assumes that the output directories exist (e.g., via git clone)
# If not, these will as fallback be created during 00_setup.R
#       * outputs/plots (in dir_plots)
#       * outputs/logs (in dir_logs)
############################################################################## #

## ########################################################################### #
# ---- 1. ESM configuration ---------------------------------------------------- 
## ########################################################################### #

CONFIG_ESM <- list(
  # Columns mapping from codebook
  cols = list(
    col_dyad         = "CoupleID",              # Couple ID number
    col_person       = "PpID",                  # Participant ID number
    col_part_no      = "partner_no",            # Partner number
    col_gen_com      = "GeneralComments",       # General comments provided by participant or researcher 
    col_ESM_com      = "ESMComments",           # ESM comments provided by participant or researcher 
    col_beep         = "beepno",                # beepnumber
    col_ts_sched     = "timeStampScheduled",    # time stamp the notification was scheduled for
    col_ts_sent      = "timeStampSent",         # time stamp the notification was sent
    col_ts_start     = "timeStampStart",        # time stamp the interaction started (questionnaire was opened)
    col_ts_stop      = "timeStampStop",         # time stamp the interaction was completed (questionnaire was finished)
    col_ots_sent     = "originalTimeStampSent", # in case of reminders, time stamp of the original interaction
    col_compl        = "compliance",            # proportion complete beeps / number of beeps in dataset (per participant)
    col_start        = "started",               # whether a beep was started
    col_end          = "complete"               # whether a beep was completed (based on non-conditional items)
  ),
  # Variables mapping from codebook
  vars = list(
    var_anger        = "angry",               # Anger
    var_stress       = "stress",              # Stress
    var_sad          = "sad",                 # Sadness
    var_NA_own       = "NA_own",              # Own negative affect
    var_PA_own       = "PA_own",              # Own positive affect
    var_anhed        = "anhedonia",           # Anhedonia
    var_fat          = "tired",               # Fatigue
    var_insec        = "insecure",            # Insecurity
    var_part_pres    = "partner_presence",    # Partner presence
    var_part_cont    = "partner_contact",     # Contact with partner
    var_neg_part     = "negevent_partner",    # Unpleasant moment with partner
    var_pos_part     = "posevent_partner",    # Enjoyable moment with partner
    var_reass_own    = "reassurance_own",     # own reassurance seeking
    var_IER          = "extrinsicIER",        # Extrinsic interpersonal emotion regulation
    var_expr_own     = "expression_own",      # Emotion expression
    var_agency_own   = "dominance_own",       # Own agency/dominance
    var_comm_own     = "affiliation_own",     # Own communion/affiliation    
    var_reass_part   = "reassurance_partner", # perceived partner reassurance seeking
    var_expr_part    = "expression_partner",  # Emotion expression (perceived)
    var_agency_part  = "dominance_partner",   # Partner agency/dominance
    var_comm_part    = "affiliation_partner", # Partner communion/affiliation    
    var_pres_oth     = "presence_others",     # Presence of others
    var_cont_oth     = "contact_others",      # Contact with others
    var_neg_gen      = "negevent_general",    # Negative event general
    var_pos_gen      = "posevent_general",    # Positive event general
    var_lonely       = "lonely",              # Loneliness
    var_rumin        = "rumination",          # Rumination about relationship
    var_posthoughts  = "posthoughts",         # Positive reminiscence about relationship
    var_expr_des     = "expression_desire",   # Emotion expression desire
    var_aff_des      = "affection_desire",    # Affection desire
    var_sex_des_own  = "sexualdesire_own",    # Sexual desire
    var_love         = "loving",              # Loving towards partner
    var_PA_part      = "PA_partner",          # Partner positive affect
    var_NA_part      = "NA_partner",          # Partner negative affect    
    var_perc_resp    = "perc_respons",        # Perceived partner responsiveness
    var_press        = "pressure",            # Pressure not to feel sad or stressed
    var_sex_des_part = "sexualdesire_partner" # Perceived desire partner
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
    limits_PA_part       = c(0, 100),
    limits_NA_part       = c(0, 100),
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
    col_person  = "PpID",
    col_dyad    = "CoupleID",
    col_age     = "AgeYEARS",
    col_gender  = "gender",
    col_nat     = "nationality",
    col_etn     = "etnicity",
    col_edu     = "edu",
    col_child   = "childrenYN",
    col_liv_tog = "livingTogether",
    col_rel_dur = "RelDurMonths",
    col_med     = "medication_none" # NA = no, 1=yes
  ),
  # Mapping of column values to their labels
  value_labels = list(
    col_gender  = c("1" = "Male", "2" = "Female", "3" = "Other"),
    col_nat     = c("4" = "Belgian", "5" = "Dutch", "6" = "Other"),
    col_etn     = c("1" = "Asian", "2" = "Black or AFrican-American", 
                    "3" = "Spanish or Latino", "4" = "White", "5" = "Other"),
    col_edu     = c("1" = "Primary School", "2" = "High School", 
                    "3" = "Bachelor", "4" = "Master", "5" = "PhD"),
    col_child   = c("0" = "No", "1" = "Yes"),
    col_liv_tog = c("1" = "No", "2" = "Yes"),
    col_med     = c("0" = "Not Medicated", "1" = "Medicated") # NA = no, 1=yes
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
    col_dyad        = "CoupleID",
    col_person      = "PpID",
    col_topic       = "topic",
    col_segment     = "timepoint",
    col_duration    = "duration_minutes"
  ),
  # Variables mapping from codebook
  vars = list(
    var_NA_own      = "neg_aff_own",        # Own negative affect
    var_NA_part     = "neg_aff_partner",    # Partner negative affect    
    var_PA_own      = "pos_aff_own",        # Own positive affect
    var_PA_part     = "pos_aff_partner",    # Partner positive affect
    var_press       = "press_sad",          # Pressure not to feel sad or stressed
    var_reass_part  = "perc_reassk",        # Perceived partner reassurance seeking
    var_suppression = "suppression",        # Own suppression
    var_IER         = "extr_IER",           # Extrinsic interpersonal emotion regulation
    var_agency_own  = "own_agency",         # Own agency
    var_agency_part = "partner_agency",     # Partner agency
    var_comm_own    = "own_communion",      # Own communion
    var_comm_part   = "partner_communion"   # Partner communion
  ),
  # Valid Ranges (Min, Max) for each variable
  ranges = list(
    limits_NA_own      = c(0, 100),
    limits_NA_part     = c(0, 100),
    limits_PA_own      = c(0, 100),
    limits_PA_part     = c(0, 100),
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
    col_dyad     = "CoupleID",
    col_person   = "PpID",
    col_start    = "StartDate", # date and time questionnaire was started by participant
    col_end      = "EndDate",   # date and time questionnaire was completed by participant
    col_duration = "Duration"   # duration to complete in seconds
  ),
  # Variables mapping from codebook
  vars = list(
    # Negative interaction items
    var_anger_neg            = "Anger_neg",
    var_stress_neg           = "Stress_neg",
    var_sad_neg              = "Sad_neg",
    var_happy_neg            = "Happy_neg",
    var_love_neg             = "Lovingly_neg",
    var_close_neg            = "Close_neg",
    var_ignored_neg          = "Ignored_neg",
    var_irritated_neg        = "Irritated_neg",
    var_hurt_neg             = "Hurt_neg",
    var_guilt_neg            = "Guilt_neg",
    var_indifferent_neg      = "Indifferent_neg",
    var_emo_connected_neg    = "EmoConnected_neg",
    var_emo_match_neg        = "EmoMatch_neg",
    var_s_care_about_p_neg   = "SCareAboutP_neg", # Self Care About Partnet
    var_p_care_about_s_neg   = "PCareAboutS_neg", # Partner Care ABout Self
    var_p_free_neg           = "Pfree_neg",
    var_s_free_neg           = "Sfree_neg",
    var_satisfied_conv_neg   = "SatisfiedWConversation_neg",
    var_representive_neg     = "Representive_neg",
    # Positive interaction items
    var_anger_pos            = "Anger_pos",
    var_stress_pos           = "Stress_pos",
    var_sad_pos              = "Sad_pos",
    var_happy_pos            = "Happy_pos",
    var_love_pos             = "Lovingly_pos",
    var_close_pos            = "Close_pos",
    var_ignored_pos          = "Ignored_pos",
    var_irritated_pos        = "Irritated_pos",
    var_hurt_pos             = "Hurt_pos",
    var_guilt_pos            = "Guilt_pos",
    var_indifferent_pos      = "Indifferent_pos",
    var_emo_connected_pos    = "EmoConnected_pos",
    var_emo_match_pos        = "EmoMatch_pos",
    var_s_care_about_p_pos   = "SCareAboutP_pos",
    var_p_care_about_s_pos   = "PCareAboutS_pos",
    var_p_free_pos           = "Pfree_pos",
    var_s_free_pos           = "Sfree_pos",
    var_satisfied_conv_pos   = "SatisfiedWConversation_pos",
    var_representive_pos     = "Representive_pos"
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

## ########################################################################### #
# ---- 5. CONFIG LOAD AND CLEAN FUNCTIONS --------------------------------------
## ########################################################################### #

load_config <- function(config, to_global = TRUE) {
  # 1. Select the config list
  cfg <- switch(config,
                "ESM"  = CONFIG_ESM,
                "BG"   = CONFIG_BG,
                "VMR"  = CONFIG_VMR,
                "POST" = CONFIG_POST)
  
  if(is.null(cfg)) stop(paste("Configuration not found for:", config))
  # 2. Unpack sublists to Global Environment except if to_global = FALSE
  if(to_global) {
    sublists_to_unpack <- names(cfg)
    for (sublist in sublists_to_unpack) {
      list2env(cfg[[sublist]], envir = .GlobalEnv)
    }
    cat(sprintf("✅ %s config unpacked to Global Env (Sublists: %s).\n", 
                config, paste(sublists_to_unpack, collapse=", ")))  }
  list2env(list(cols = cfg$cols, vars = cfg$vars, ranges = cfg$ranges,
                scales = cfg$scales), envir = .GlobalEnv)
  # 3. Return the config object invisibly
  invisible(cfg)
}

clean_config <- function(config) {
  # 1. Get load_config to know WHAT to remove, to_global = FALSE to not unpack
  cfg <- load_config(config, to_global = FALSE) 
  # 2. Collect all variable names
  vars_to_remove <- c()
  sublists_to_remove <- names(cfg)
  for (sublist in sublists_to_remove) {
    vars_to_remove <- c(vars_to_remove, names(cfg[[sublist]]))
  }
  # 3. Add containers
  containers <- c("cols", "vars", "ranges", "scales")
  vars_to_remove <- c(vars_to_remove, containers)
  # 4. Limit to what exists in GlobalEnv to avoid warnings
  vars_to_remove <- vars_to_remove[sapply(vars_to_remove, exists, envir = .GlobalEnv)]
  vars_to_remove <- unique(vars_to_remove) # avoid attempting to remove twice
  # 5. Remove them from GlobalEnv
  if(length(vars_to_remove) > 0) {
    rm(list = vars_to_remove, envir = .GlobalEnv)
    cat(sprintf("🧹 %s vars removed from Global Env.\n", config))
  } 
}

# Validation function to check if if columns/vars mapped in the CONFIG exist in the datset
validate_config <- function(config, dataset) {
  # 1. Get the config locally (not to global env)
  cfg <- load_config(config, to_global = FALSE)
  # 2. Gather all expected column names (in GLOBAL_SETTINGS config_sublists_with_variables)
  vars_required <- c()
  sublists_to_check <- intersect(names(cfg), config_sublists_with_variables)
  for (sublist in sublists_to_check) {
    vars_required <- c(vars_required, unlist(cfg[[sublist]]))
  }
  # 3. Compare against the actual dataframe
  vars_missing <- setdiff(vars_required, names(dataset))
  # 4. Stop if any are missing
  if(length(vars_missing) > 0) {
    cat(sprintf("\n\n!!! ERROR: The '%s' dataset is missing these variables:\n%s\n", 
                config, 
                paste(vars_missing, collapse = ", ")))
  } else {
    cat(sprintf("✅ %s dataset validated: All %d required variables found (checked: %s).\n", 
                config, length(vars_required), paste(sublists_to_check, collapse=", ")))
  }
}

# custom analysis qPCR data: for fig 3B/ramfacs

source('./0-general_functions_main.R') # Source the general_functions file before running this

# User inputs  ----
# choose file name, title for plots (file name starts in the same directory as Rproject)

# flnm <- 'q39_S052_e coli dil exp_28-10-22'  
# title_name <-'exponential: Limit of detection of splicing-qPCR'
# titlename_short <- 'q39_S052_exp'

flnm <- 'q32_S046 E coli dils_6-6-22' # for stationary phase data
title_name <- 'S15b_RAM dilutions_q32' # older name for conjug ram facs: '3B Limit of detection of splicing-qPCR'
titlename_short <- 'q32_S046'

# Sample name modifiers 

sample_name_translator <- c('Base strain' = 'Inf', # changes the LHS into the RHS
                            'ntc' = 'Inf',
                            '51' = '0',
                            '1/|,' = '') # remove commas and convert the 1/x into x 

target_name_translator <- c('U64' = 'Spliced product',
                             'gfpbarcode' = 'Ribozyme',
                             '16s' = '16S rRNA') # regex to change the target names for publication

# Input the data ----

.df <- get_processed_datasets(flnm)

# Processing ----

# remove samples that are not relevant
forplotting_cq.dat <- filter(.df, !str_detect(Sample_category, 'conjug')) %>% 
  mutate('Fraction of Transconjugant E.coli' = 
           (str_replace_all(assay_variable, sample_name_translator) %>% 
              as.numeric %>% {1/(1+.)} # convert to numbers and to fraction (1:1 -> 0.5, 1:10 -> 1/11 ..)
            ),
         .before = assay_var.horz_label) %>% 
  
  mutate(across(Target_name, ~ str_replace_all(.x, target_name_translator)))


# Plotting ----

plt_copies <- {plot_facetted_assay(.yvar_plot = Copies.per.ul.template, .xvar_plot = `Fraction of Transconjugant E.coli`, flipped_plot = FALSE,
                                  .xaxis.label.custom = NULL) +
    theme(legend.position = 'top')} %>% 
  format_logscale_x() %>% format_logscale_y()


plt_cq <- {plot_facetted_assay(.yvar_plot = 40 - CT, .xvar_plot = `Fraction of Transconjugant E.coli`, flipped_plot = FALSE,
                                             .xaxis.label.custom = NULL) +
    theme(legend.position = 'top')} %>% 
  format_logscale_x()

# Single panel plot
plt_monopanel_copies_w_mean <- {plot_facetted_assay(.yvar_plot = Copies.per.ul.template, .xvar_plot = `Fraction of Transconjugant E.coli`, flipped_plot = FALSE, 
                                             .facetvar_plot = NULL, .colourvar_plot = Target_name,
                                   .xaxis.label.custom = NULL) +
    
    # geom_point(aes(y = mean_Copies.per.ul.template), shape = '-', size = 5, show.legend = FALSE) + # show the means
    geom_smooth(aes(y = mean_Copies.per.ul.template), 
                data = filter(forplotting_cq.dat, `Fraction of Transconjugant E.coli` > 1e-5), # constrain data
                method = 'lm', 
                alpha = .01, show.legend = FALSE) +
    
    theme(legend.position = 'top')} %>% 
  format_logscale_x() %>% format_logscale_y()


# plot only U64 for presentation

plt_U64_copies_w_mean <- 
  {plot_facetted_assay(.data = filter(forplotting_cq.dat, str_detect(Target_name, 'Spliced')),
                       
                       .yvar_plot = Copies.per.ul.template, .xvar_plot = `Fraction of Transconjugant E.coli`, flipped_plot = FALSE,
                       .facetvar_plot = NULL, .colourvar_plot = NULL,
                       .xaxis.label.custom = NULL) +
      
    # geom_point(aes(y = mean_Copies.per.ul.template), shape = '-', size = 5, show.legend = FALSE) + # show the means
    geom_smooth(aes(y = mean_Copies.per.ul.template), 
                data = filter(forplotting_cq.dat, str_detect(Target_name, 'Spliced'), `Fraction of Transconjugant E.coli` > 1e-5), # constrain data
                method = 'lm', 
                alpha = .2, show.legend = FALSE) +
    
    theme(legend.position = 'top')} %>% 
  format_logscale_x() %>% format_logscale_y()

# Save plot ----

# ggsave(plot_as(titlename_short, '-Cq'), plt_cq, width = 4.5, height = 4)
# ggsave(plot_as(titlename_short), plt_copies, width = 4.5, height = 4)
ggsave(plot_as(titlename_short, '-copies'), plt_monopanel_copies_w_mean, width = 3.7, height = 4)
ggsave(plot_as(titlename_short, '-spliced'), plt_U64_copies_w_mean, width = 3.7, height = 4)
ggsave(str_c('qPCR analysis/Archive/', titlename_short, '-spliced.pdf'), 
       plt_U64_copies_w_mean, width = 3.7, height = 2) # save as PDF


# Save data ----

# Save formatted data (goes with publication)

# arrange important columns first
select(forplotting_cq.dat,
       'Fraction of Transconjugant E.coli', Target_name, Copies.per.ul.template, mean_Copies.per.ul.template, 
       Sample_category,
       everything()) %>%
  
write_csv(str_c('excel files/paper_data/', 'ramfacs-', titlename_short, '.csv', sep = ''),
          na = '')

# save clean and concise data for paper
clean_data <- 
  
  # remove ntcs and keep only spliced products
  filter(forplotting_cq.dat, assay_variable != 'ntc', str_detect(Target_name, 'Spliced')) %>% 
  
  # select only relevant columns
  select('Fraction of Transconjugant E.coli',
         Copies.per.ul.template, mean_Copies.per.ul.template) %>% 
  
  # arrange by increasing fraction
  arrange(`Fraction of Transconjugant E.coli`)


output_path <- '../../Writing/RAM paper outputs/Archive'

write.csv(clean_data, str_c(output_path, '/', title_name, '.csv')) # save data as csv

import pandas as pd
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
import statsmodels.api as sm
from statsmodels.formula.api import ols
import statsmodels.api as sm
import statsmodels.formula.api as smf

DIR_DATA = '/global/homes/c/czarakas/TREE2H2O/code/stomatal_slope_experiments/preprocessing/generate_stomatal_slope_ranges/'
FNAME = 'WUEdatabase_merged_Lin_et_al_2015_NCC.csv'

PFT_CATEGORIES=["Evergreen needleleaf", "Evergreen broadleaf", "Deciduous broadleaf", 
                "Shrub", "C3 grassland", "C4 grassland",  #"Tundra",
                "C3 cropland"]

PFTS = ["NE Temp. Tree", "NE Bor. Tree", "BE Trop. Tree", "BE Temp. Tree", 
        "BD Trop. Tree", "BD Temp. Tree", "BD Bor. Tree",
        "BE Shrub", "BD Temp. Shrub", "BD Bor. Shrub",
        "C3 Grass", "C4 grass",
        "C3 Crop"]

PFT_NUMS = [1, 2, 4, 5,
           6, 7, 8,
           9, 10, 11, 
           13, 14,
           15] # note no observations in Lin et al. for PFT #3 or #12

def calc_sat_vapor_pressure(temp_C):
    # Inputs: Temperature in Celsius
    # Outputs: VPD in kPa
    
    # Equation from equation 17 in Huang et al, 2018
    term1 = 34.494-(4924.99/(temp_C+237.1))
    term2 = (temp_C+105)**1.57
    return (np.exp(term1)/term2)/1000

def load_data(dir_data=DIR_DATA, fname=FNAME):
    df = pd.read_csv(dir_data+fname, encoding = "ISO-8859-1")
    return df

def process_data(df, g0=0):#g0=1e-6):
    df['Tleaf']=np.where(df['Tleaf']>-9999,df['Tleaf'], np.nan)

    # calculate saturation vapor pressure based on leaf temperature
    df['Saturation_Vapor_Presure_kPa']=calc_sat_vapor_pressure(df.Tleaf)

    # calculate vapor pressure (using sat. vapor pressure and VPD)
    df['Vapor_Presure_kPa'] = df['Saturation_Vapor_Presure_kPa']-df.VPD

    # drop observations where vapor pressure from this calculation is negative
    df['Vapor_Presure_kPa'] = np.where(df['Vapor_Presure_kPa']>=0, df['Vapor_Presure_kPa'], np.nan)

    # calculate relative humidity
    df['RH_frac']=df['Vapor_Presure_kPa']/df['Saturation_Vapor_Presure_kPa']

    # drop RH where RH < 0 (this shouldn't be possible)
    df['RH_frac']=np.where(df['RH_frac']>=0, df['RH_frac'], np.nan)
    
    df['xvals_BB']=df['Photo']*df['RH_frac']/df['CO2S']
    df['yvals_BB']=df['Cond']- g0 
    
    return df

def classify_observations(df):
    
    df['PFT_category'] = ''
    df['PFT_num'] = 0
    
    
    # Assign each observation to a PFT category (used in De Kauwe et al. 2015 and CLM5)
    df.loc[df['Type']=='gymnosperm', ['PFT_category']] = "Evergreen needleleaf"
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='evergreen'), ['PFT_category']] = "Evergreen broadleaf"
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous'), ['PFT_category']] = "Deciduous broadleaf"
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='evergreen'), ['PFT_category']] = "Evergreen broadleaf"
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous'), ['PFT_category']] = "Deciduous broadleaf"
    df.loc[df['Plantform']=='shrub', ['PFT_category']] = "Shrub"
    # df.loc[df['Tregion']=='Arctic', ['PFT_category']] = "Tundra" # Note that this was based off DeKauwe et al. which had an Arctic PFT
    df.loc[(df['Plantform']=='grass') & (df['Pathway']=='C3'), ['PFT_category']] = "C3 grassland"
    df.loc[(df['Plantform']=='grass') & (df['Pathway']=='C4'), ['PFT_category']] = "C4 grassland"
    df.loc[(df['Plantform']=='crop') & (df['Pathway']=='C3'), ['PFT_category']] = "C3 cropland"
    df.loc[(df['Plantform']=='crop') & (df['Pathway']=='C4'), ['PFT_category']] = "C4 cropland"
    
    # Assign each observation to a CLM5 PFT (narrower classification than above)
    df.loc[(df['Type']=='gymnosperm') & (df['Tregion']=='temperate'), ['PFT_num']] = 1
    df.loc[(df['Type']=='gymnosperm') & (df['Tregion']=='boreal'), ['PFT_num']] = 2
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='evergreen') & (df['Tregion']=='tropical'), ['PFT_num']] = 4
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='evergreen') & (df['Tregion']=='tropical'), ['PFT_num']] = 4
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='evergreen') & (df['Tregion']=='temperate'), ['PFT_num']] = 5
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='evergreen') & (df['Tregion']=='temperate'), ['PFT_num']] = 5
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous') & (df['Tregion']=='tropical'), ['PFT_num']] = 6
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous') & (df['Tregion']=='tropical'), ['PFT_num']] = 6
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous') & (df['Tregion']=='temperate'), ['PFT_num']] = 7
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous') & (df['Tregion']=='temperate'), ['PFT_num']] = 7
    df.loc[(df['Plantform']=='tree') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous') & (df['Tregion']=='boreal'), ['PFT_num']] = 8
    df.loc[(df['Plantform']=='savanna') & (df['Type']=='angiosperm') & 
           (df['Leafspan']=='deciduous') & (df['Tregion']=='boreal'), ['PFT_num']] = 8
    df.loc[(df['Plantform']=='shrub') & (df['Leafspan']=='evergreen'), ['PFT_num']] = 9
    df.loc[(df['Plantform']=='shrub') & (df['Leafspan']=='deciduous') & 
           (df['Tregion']=='temperate'), ['PFT_num']] = 10
    df.loc[(df['Plantform']=='shrub') & (df['Leafspan']=='deciduous') & 
           (df['Tregion']=='boreal'), ['PFT_num']] = 11
    df.loc[(df['Plantform']=='shrub') & (df['Leafspan']=='deciduous') & 
           (df['Tregion']=='Arctic'), ['PFT_num']] = 11
    df.loc[(df['Plantform']=='grass') & (df['Pathway']=='C3'), 
           ['PFT_num']] = 13
    df.loc[(df['Plantform']=='grass') & (df['Pathway']=='C4'), 
           ['PFT_num']] = 14
    df.loc[(df['Plantform']=='crop') & (df['Pathway']=='C3'), 
           ['PFT_num']] = 15
    df.loc[(df['Plantform']=='crop') & (df['Pathway']=='C4'), 
           ['PFT_num']] = 17

    return df

def calc_BB_slope(df, PFT_categories=PFT_CATEGORIES, random_effect=True):
    df_BB = df[df.xvals_BB>0]
    df_BB = df_BB[df_BB.yvals_BB>0]
    
    PFT_avgs = np.zeros(np.size(PFT_categories))
    predictions = []
    
    for i, PFT_category in enumerate(PFT_categories):
        df_subset = df_BB[df_BB['PFT_category']==PFT_category]
        
        if random_effect:
            # Fit mixed effects model (where species is random effect)
            model = smf.mixedlm("yvals_BB ~ xvals_BB-1", df_subset, 
                                groups=df_subset["Species"],
                                re_formula="0 + xvals_BB")
        else:
            model = ols("yvals_BB ~ xvals_BB-1", data=df_subset) #-1
        results = model.fit()
        params = results.params
        ipredictions = model.predict(params)
        predictions.append(ipredictions)
        
        PFT_avgs[i] = params['xvals_BB']
        
    return [PFT_avgs, df_BB, predictions]

def calc_BB_slope_range(df, PFT_categories=PFT_CATEGORIES,
                       replicate_cutoff=0):
    
    #Subset dataset for Ball-Berry calculation
    df_BB = df[df.xvals_BB>0]
    df_BB = df_BB[df_BB.yvals_BB>0]
    df_BB = df_BB[df_BB.RH_frac>0.1]
    
    #Create empty lists
    PFT_groupings = []
    g1_5pct = []
    g1_mean = []
    g1_95pct = []
    num_datapoints = []
    num_species = []
    species_g1s = []
    list_count_missing_replicates = []
    list_num_replicates_not_counted = []
    list_num_replicates_counted = []
    
    for j, PFT_category in enumerate(PFT_categories):
        
        df_subset = df_BB[df_BB['PFT_category']==PFT_category]
        
        df_subset_species = df_subset.groupby('Species').mean()
        
        g1s = np.zeros(len(df_subset_species))
        g1s_se = np.zeros(len(df_subset_species))
        xvals_mean = np.zeros(len(df_subset_species))
        yvals_fit = np.zeros(len(df_subset_species))
        g1s[:] = np.nan
        g1s_se[:] = np.nan
        xvals_mean[:] = np.nan
        yvals_fit[:] = np.nan
        
        count_missing_replicates = 0
        num_replicates_not_counted = 0
        num_replicates_counted = 0
        
        for i, species in enumerate(df_subset_species.index):
            df_subset_1species = df_subset[df_subset['Species']==species]
            xvals_subset = df_subset_1species['xvals_BB']
            yvals_subset = df_subset_1species['yvals_BB']
            num_replicates = np.size(xvals_subset)
            
            # Fit model
            model = sm.OLS(yvals_subset, xvals_subset)
            results = model.fit()
            params = results.params
            predictions = model.predict(params)
            
            if num_replicates<replicate_cutoff:
                g1s[i]=np.nan
                g1s_se[i]=np.nan
                count_missing_replicates = count_missing_replicates + 1
                num_replicates_not_counted = num_replicates_not_counted + num_replicates
                last_ind_skipped = i
            else:
                g1s[i]=params[0]
                g1s_se[i]=results.bse[0]
                xvals_mean[i] = np.nanmean(xvals_subset)
                yvals_fit[i] = np.nanmean(predictions)
                num_replicates_counted = num_replicates_counted + num_replicates
        

        df_subset_species['g1']=g1s
        df_subset_species['g1_se']=g1s_se
        df_subset_species['xvals_mean']=xvals_mean
        df_subset_species['yvals_fit']=yvals_fit
        
        # Save statistics for PFT category
        pft_min = np.nanmin(df_subset_species['g1'].values)
        pft_5pct = np.nanpercentile(df_subset_species['g1'].values, 5)
        pft_10pct = np.nanpercentile(df_subset_species['g1'].values, 10)
        pft_mean = np.nanmean(df_subset_species['g1'].values)
        pft_median = np.nanmedian(df_subset_species['g1'].values)
        pft_90pct = np.nanpercentile(df_subset_species['g1'].values, 90)
        pft_95pct = np.nanpercentile(df_subset_species['g1'].values, 95)
        pft_max = np.nanmax(df_subset_species['g1'].values)
        
        # 
        PFT_groupings.append(PFT_category)
        g1_5pct.append(pft_5pct)
        g1_mean.append(pft_mean)
        g1_95pct.append(pft_95pct)
        num_datapoints.append(len(df_subset))
        num_species.append(len(df_subset_species.index))
        species_g1s.append(g1s)
        list_count_missing_replicates.append(count_missing_replicates)
        list_num_replicates_not_counted.append(num_replicates_not_counted)
        list_num_replicates_counted.append(num_replicates_counted)
        
    df_g1 = pd.DataFrame(
        {'PFT_category': PFT_groupings,
         'g1_5pct': g1_5pct,
         'g1_mean': g1_mean,
         'g1_95pct': g1_95pct,
         'num_datapoints': num_datapoints,
         'num_species': num_species,
         'count_missing_replicates':list_count_missing_replicates,
         'num_replicates_not_counted':list_num_replicates_not_counted,
         'num_replicates_counted':list_num_replicates_counted,
         'species_g1s':species_g1s
        })
        
    return [df_g1, df_BB]
rule make_local_catalogue:
    output:
        outpath = 'catalogues/{activity}_{source}_CMIP6.csv.gz'
    
    params:
        root_path = lambda w: config[f"root_{w.source}"] + f'/{w.activity}/',
        depth = 9,
    conda:
        "dustysnake"
    threads: 4

    script:
        '../scripts/make_catalogue.py'

rule make_available_data_tracker:
    input:
        reference = 'config/reference_data_request.yaml',
    
    output:
        outpath = 'config/.data_trackers/{experiment}_{source}_CMIP6.yaml'

    notebook:
        '../notebooks/make_available_data_tracker.py.ipynb'


rule build_catalogues:
    input:
        expand('catalogues/{activity}_{source}_CMIP6.csv.gz', 
                activity = config['activities'], 
                source = config['sources']),
        # 'catalogues/AerChemMIP_noresm_CMIP6.csv.gz',
        # 'catalogues/RFMIP_noresm_CMIP6.csv.gz')
        # 'catalogues/CMIP_nirdCMIPtemp_CMIP6.csv.gz'
    output:
        table='catalogues/merge_CMIP6.csv',
        json='catalogues/merge_CMIP6.json'
    conda:
        "dustysnake"
    notebook:
        '../notebooks/merge_catalogues.py.ipynb'        

rule get_data_intake:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        data_tracker = ancient('config/.data_trackers/{experiment}_{model}_CMIP6.yaml')
    output:
        outpath = expand(output_format['single_variable'], ext='nc', allow_missing=True)
    params:
        accumalative_vars = config['accumalative_vars'],
        regrid = False
    conda:
        "geocat"

    log:
        "logs/calc_clim/{variable}_{model}_{experiment}_{freq}_nc.log"
    notebook:
        "../notebooks/get_data_intake.py.ipynb"


rule get_data_intake_zarr:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        data_tracker = ancient('config/.data_trackers/{experiment}_{model}_CMIP6.yaml')
    output:
        outpath = directory(expand(output_format['single_variable'], ext='zarr', allow_missing=True))
    params:
        accumalative_vars = config['accumalative_vars'],
        regrid = False
    
    log:
        "logs/calc_clim/{variable}_{model}_{experiment}_{freq}_zar.log"
    notebook:
        "../notebooks/get_data_intake.py.ipynb"

rule calc_global_regional_erf_table:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        data_tracker = ancient('config/.data_trackers/{experiment}_{model}_CMIP6.yaml')    
    output:
        outpath = outdir + '{experiment}/ERFs/ERF_tables/{experiment}_{model}.csv'
    threads: 4

    log:
        "logs/erf_tables/{model}_{experiment}.log"
    notebook:
        "../notebooks/forcing_calculations/calc_global_regional_erf.py.ipynb"


rule calc_regional_erf_table:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        data_tracker = ancient('config/.data_trackers/{experiment}_{model}_CMIP6.yaml'),
    output:
        outpath = outdir + '{experiment}/ERFs/ERF_regional_tables/{experiment}_{model}_regional.csv'
    threads: 4
    log:
        "logs/erf_tables/{model}_{experiment}_regional.log"
    notebook:
        "../notebooks/forcing_calculations/calc_global_regional_erf.py.ipynb"

rule column_integrate_cdnc_zarr:
    input:
        cdnc = lambda w: expand(output_format['single_variable'], model='EC-Earth3-AerChem', experiment=w.experiment,
                freq='Amon', variable='cdnc',ext='zarr'),
        ta = lambda w: expand(output_format['single_variable'], model='EC-Earth3-AerChem', experiment=w.experiment,
                freq='Amon', variable='ta', ext='zarr'),
    output:
        outpath = outdir + '{experiment}/derived_variables/cdncvi/cdncvi_EC-Earth3-AerChem_{experiment}_Ayear.nc'
    conda:
        "geocat"
    
    params:
        p1=10000

    notebook:
        "../notebooks/derive_column_integrated_cdnc.py.ipynb"


rule column_integrate_cdnc:
    input:
        cdnc = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                freq='Amon', variable='cdnc',ext='nc'),
        ta = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                freq='Amon', variable='ta', ext='nc'),
    output:
        outpath = outdir + '{experiment}/derived_variables/cdncvi/cdncvi_{model}_{experiment}_Ayear.nc'
    conda:
        "geocat"

    wildcard_constraints:
        model="(?!UKESM1-0-LL|EC-Earth3-AerChem).*"
    
    params:
        p1=10000

    notebook:
        "../notebooks/derive_column_integrated_cdnc.py.ipynb"

    
rule column_integrate_cdnc_UKESM:
    input:
        cdnc = lambda w: expand(output_format['single_variable'], model='UKESM1-0-LL', experiment=w.experiment,
                freq='Amon', variable='cdnc', ext='nc'),
        ta = lambda w: expand(output_format['single_variable'], model='UKESM1-0-LL', experiment=w.experiment,
                freq='Amon', variable='ta', ext='nc'),
        pfull = lambda w: expand(output_format['single_variable'], model='UKESM1-0-LL', experiment=w.experiment,
                freq='Amon', variable='pfull', ext='nc'),
    output:
        outpath = outdir + '{experiment}/derived_variables/cdncvi/cdncvi_UKESM1-0-LL_{experiment}_Ayear.nc'
    conda:
        "geocat"
    params:
        p1=10000

    notebook:
        "../notebooks/derive_column_integrated_cdnc.py.ipynb"




rule derive_column_integrated_load_airmass:
    input:
        mmr = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                freq='Amon', variable=config['burdens_dict'].get(w.variable), ext='nc'),
        airmass = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                freq='Amon', variable='airmass', ext='nc'),
    output:
        outpath = outdir + '{experiment}/derived_variables/{variable}/{variable}_{model}_{experiment}_Ayear.nc'
    wildcard_constraints:
        model='UKESM1-0-LL',
        variable = 'concdust|concpm1|concpm10|concpm2p5|concso4|concss|concsoa|concoa|conch2oaer|concbc|concnh4|concno3|hno3'
    conda: 
        "geocat"

    notebook:
        "../notebooks/derive_column_integrated_load.py.ipynb"

rule derive_column_integrated_load:
    input:
        mmr = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                 variable=config['burdens_dict'].get(w.variable), freq='Amon', ext='nc'),
    output:
        outpath = outdir + '{experiment}/derived_variables/{variable}/{variable}_{model}_{experiment}_Ayear.nc'
    wildcard_constraints:
        variable = 'concdust|concpm1|concpm10|concpm2p5|concso4|concss|concsoa|concoa|conch2oaer|concbc|conco3|concnh4|concno3',
        model="(?!UKESM1-0-LL).*"
    conda: 
        "geocat"

    notebook:
        "../notebooks/derive_column_integrated_load.py.ipynb"


rule mask_dust_regions:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
    output:
        outpath = outdir + 'masks/dust_regions.nc'
    notebook:
        "../notebooks/mask_dust_regions.py.ipynb"


rule derived_windspeed:
    input:
        u = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                    freq=w.freq, variable='ua'),
        v = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                    freq=w.freq, variable='va'),
    output:
        outpath = outdir + '{experiment}/derived_variables/windspeed/windspeed_{model}_{experiment}_{freq}.nc'
    notebook:
        "../notebooks/derive_windspeed.py.ipynb"

rule cmip6_to_aerocom_fmt:
    input:
        paths = lambda w: get_paths(w,w.variable,w.experiment,grid_label=config['default_grid_label'])
    output:
        outpath = outdir+'{model}_{experiment}/renamed/converted_CMIP6_aerocom_{variable}.txt'
    
    notebook:
        "../convert_to_aerocom_fmt.py.ipynb"

rule calc_friction_velocity:
    input:
        tauu = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                    freq='Amon', variable='tauu',ext='nc'),
        tauv = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                    freq='Amon', variable='tauv',ext='nc'),
        pa = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                    freq='Amon', variable='ps',ext='nc'),
        
        tas = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                freq='Amon', variable='tas', ext='nc'),
        mask = outdir + 'masks/dust_regions.nc',
        universial_area_mask = 'workflow/input_data/common_grid.nc', 
        model_area_mask = 'workflow/input_data/gridarea_{model}.nc'
    output:
        outpath = outdir + '{experiment}/derived_variables/ustar/ustar_{model}_{experiment}_Ayear.nc'

    notebook:
        "../notebooks/calc_friction_velocity.py.ipynb"

rule calc_cloud_fraction:
    input:
        cl = lambda w: expand(output_format['single_variable'], model=w.model, experiment=w.experiment,
                    freq='Ayear', variable='cl',ext='nc'),
    wildcard_constraints:
        height = 'low|middle|high'
    output:
        outpath = outdir + '{experiment}/derived_variables/cl{height}/cl{height}_{model}_{experiment}_Ayear.nc'
    conda:
        "geocat"
    notebook:
        "../notebooks/calc_cloud_fraction.py.ipynb"

    
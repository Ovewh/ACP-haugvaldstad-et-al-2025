import xarray as xr
import xesmf as xe
from pyclim_noresm.aerosol_forcing import merge_exp_ctrl
from pyclim_noresm.general_util_funcs import global_avg
import numpy as np
import pandas as pd
import cftime
import time
def get_forcing(forcing_var: str,dataframes: dict):
    k = next(iter(dataframes))
    outdf = pd.DataFrame(index=dataframes.keys(), columns=dataframes[k].columns)
    for k,df in dataframes.items():
        try:
            outdf.loc[k,:] = df.loc[forcing_var]
        except KeyError:
            pass
            
    return outdf


def convert_lon_to_180(ds):
    """
    This function converts the longitude coordinates from 0/360 to -180/180
    """
    ds['lon'] =(ds['lon']+ 180) % 360 - 180
    ds = ds.sortby('lon')
    return ds

def make_consistent(dsets):
    template_ds = dsets[0]
    fixed_dsets = []
    for ds in dsets:
        ds = ds.reindex(
            {"lon": template_ds.lon, "lat": template_ds.lat}, method="nearest"
        )
        ds = ds.assign(
            {"lon_bnds": template_ds.lon_bnds, "lat_bnds": template_ds.lat_bnds}
        )
        if ds.indexes['time'].dtype == 'O':
            if np.max(ds.time.dt.year) < 1000:
                if len(ds.time) > 100:
                    freq='ME'
                else:
                    freq='YE'
                new_t = xr.date_range(start='1750',periods=len(ds.time), freq=freq)
                ds = ds.assign_coords(time=new_t)
            else:
                ds = ds.assign_coords(time=ds.indexes['time'].to_datetimeindex())
            ds = ds.drop('time_bnds',errors='ignore')

        fixed_dsets.append(ds)
        
    

    return fixed_dsets



def load_CMIP_data(path, **dataset_kwargs):
    if len(path) > 1:
        try:
            ds = xr.open_mfdataset(path, chunks={"time": 120}, **dataset_kwargs)
        except xr.MergeError:
            dvar = dataset_kwargs.pop("data_vars")
            if not isinstance(dvar, list):
                dvar = list(dvar)
            dsets = [xr.open_dataset(p, **dataset_kwargs) for p in path]
            dsets = make_consistent(dsets)
            ds = xr.concat(dsets, dim="time", data_vars=dvar)
        return ds
    else:
        dataset_kwargs.pop("data_vars")
        try:
            ds = xr.open_dataset(path[0], chunks={"time": 120}, **dataset_kwargs)
        except:
            ds = xr.open_dataset(path[0], chunks={"time": 120}, decode_times=False,**dataset_kwargs)
            ds = ds.assign(time=cftime.num2date(ds.time,units=ds.time.attrs['units']))
            
        return ds


def copy_meta_data_CMIP(attrs):
    remove_keys = [
        "source",
        "table_info",
        "variable_id",
        "tracking_id",
        "history",
        "creation_date",
        "branch_time_in_child",
        "branch_time_in_parent",
        "Conventions",
    ]
    new_attrs = {k: attrs[k] for k in set(list(attrs.keys())) - set(remove_keys)}
    return new_attrs


def compute_annual_emission_budget(ds: xr.Dataset, grid_area: xr.Dataset):
    """
    Computes annual emission budget from monthly data

    Params
    ------
        ds :  monthly emission flux,
        grid_area: area of each grid cell
    Returns
    -------
        yearly_budget: annual emission budget

    """
    if isinstance(ds,xr.Dataset):
        ds = ds[ds.variable_id]

    if ds.units == "kg m-2 s-1":
        yearly_budget = ds * 365 * 24 * 60 * 60
    else:
        yearly_budget = ds
    yearly_budget = yearly_budget * grid_area.load()
    yearly_budget = yearly_budget.sum(dim=["lon", "lat"]) * 1e-9
    yearly_budget.attrs["units"] = "Tg year-1"
    std_yearly_budget = yearly_budget.std(dim="time")
    mean_yearly_budget = yearly_budget.mean(dim="time")
    return mean_yearly_budget, std_yearly_budget

def calculate_zonal_mean(ds: xr.DataArray, 
                         hist_range = (-np.pi /2, np.pi/ 2),
                         **hist_kwargs):
    """
    computes zonal mean of dataset
    
    Parameters
    ----------
    ds: xr.DataArray
        Input data array
    hist_range: range
        Range of values to use for histogram
    **hist_kwargs: dict
        Additional keyword arguments to pass to np.histogram

    Returns
    -------
    zonal_mean: xr.DataArray
        Zonal mean of input data array
    lat_bins: xr.DataArray
        Lat bins used for histogram
    """
    # number of cells per bin
    cells_per_bin, lat_bins = np.histogram(ds.lat,range=hist_range,**hist_kwargs)
    return cells_per_bin, lat_bins
    # sum of values per bin, weighted by number of cells
    varsum_per_bin, weights = np.histogram(ds.lat,weights=ds, range=hist_range,**hist_kwargs)

    # zonal mean
    zonal_mean = varsum_per_bin / cells_per_bin

    return zonal_mean, lat_bins



def regrid_global(
    ds: xr.Dataset,
    ds_out: xr.Dataset = None,
    lon: int = 3,
    lat: int = 2,
    method: str = "conservative",
    **regridder_kwargs,
):
    """
    Return regridded model output to get all the
    models on a common grid.

    params
    --------
        ds: Dataarray containting data field that should be regriddedd
    """
    if ds_out is None:
        ds_out = xe.util.grid_global(lon, lat, cf=True)
    regridder = xe.Regridder(ds, ds_out, method=method, **regridder_kwargs)
    ds = regridder(ds, keep_attrs=True)
    return ds


def calc_error_gridded(da: xr.DataArray, time_dim: str = "year", kind="std"):
    # If the input is a dataset, select the first variable
    if isinstance(da, xr.Dataset):
        da = da[da.variable_id]
    # Calculate the standard deviation
    with xr.set_options(keep_attrs=True):
        std = da.std(dim=time_dim)
        # Calculate the standard error of the mean if requested
        if kind == "sem" or kind == "SEM":
            st_error = std / np.sqrt(len(da[time_dim]))
        else:
            st_error = std
        # Set the long name of the output
        try:
            st_error.attrs["long_name"] = "{} of {}".format(
                kind, st_error.attrs["long_name"]
            )
        except KeyError:
            st_error.attrs["long name"] = "{} of {}".format(
                kind, st_error.attrs["long name"]
            )

    return st_error


def calc_error(da: xr.DataArray, time_dim: str = "year", kind="std"):
    """
    Calculates the standard error of the mean.

    params:
        da: DataArray|Dataset containing timeseries data:

    """
    if isinstance(da, xr.Dataset):
        da = da[da.variable_id]
    with xr.set_options(keep_attrs=True):
        if "lat" in da.dims:
            da = global_avg(da)

        std = da.std(dim=time_dim)
        if kind == "sem" or kind == "SEM":
            st_error = std / np.sqrt(len(da[time_dim]))
        else:
            st_error = std
        try:
            st_error.attrs["long_name"] = "{} of {}".format(
                kind, st_error.attrs["long_name"]
            )
        except KeyError:
            st_error.attrs["long name"] = "{} of {}".format(
                kind, st_error.attrs["long name"]
            )

    return st_error

def calc_implausibility_obs(mod, 
                            obs,
                            var_obs,
                            var_mod_internal,
                            var_mod_struct,
                            var_rep,
                            thresh=3,
                            ):
    """
    For a given model prediction and observed target value the implausibility measure the distance between
    model output and target. 

    The uncertainties for model and observations must be specified as variances.

    Params:
    -------
        mod: model prediction
        obs: observed target value
        var_obs: variance of observed target value
        var_mod_internal: variance of model prediction
        var_mod_struct: variance of model structural error
        var_rep: variance of representativity error
        thresh: threshold for implausibility (default)
    Returns:
    --------
        implausibility: implausibility measure
    """
    implausibility = np.abs(mod - obs) / np.sqrt(var_obs + var_mod_internal + var_mod_struct + var_rep)
    return implausibility


def calc_relative_change(
    ds_ctrl: xr.Dataset,
    ds_exp: xr.Dataset,
    time_slice: slice = None,
    time_average: bool = False,
):
    """
    Calculate the relative change of a diagnostic between
    the control and experiment. The data is on model level
    it is integrated vertically.

    params
    ------
        ds_ctrl: dataset containing the control experiment
        ds_exp: dataset containing the perturbed experiment
        time_slice: slice time based on index

    returns
    --------
        rel_diff: dataset containing the relative difference
    """
    return _calc_change(
        ds_ctrl,
        ds_exp,
        rel_change=True,
        time_slice=time_slice,
        time_average=time_average,
    )


def calc_abs_change(
    ds_ctrl: xr.Dataset,
    ds_exp: xr.Dataset,
    time_slice=None,
    time_average: bool = False,
    vertical_sum: bool = True,
):
    """
    Calculated absolute change of diagnostic between
    the control and experiment. Data that is on model
    level is integrated vertically.

    params:
    -------
        ds_ctrl: dataset containing the control experiment
        ds_exp: dataset containing the perturbed experiment
        time_slice : slice time based on index

    """
    return _calc_change(
        ds_ctrl,
        ds_exp,
        rel_change=False,
        time_slice=time_slice,
        time_average=time_average,
        vertical_sum=vertical_sum,
    )


def _calc_change(
    ds_ctrl: xr.Dataset,
    ds_exp: xr.Dataset,
    rel_change: bool = False,
    time_slice=None,
    time_average=False,
    vertical_sum=True,
):
    vName = ds_ctrl.variable_id
    dvars = set(list(ds_ctrl.data_vars))
    keep_vars = set(["lev_bounds", "time_bounds", "lon_bnds", "lat_bnds", vName])

    with xr.set_options(keep_attrs=True):
        ds_ctrl = ds_ctrl.drop_vars(dvars - keep_vars).squeeze()
        ds_exp = ds_exp.drop_vars(dvars - keep_vars).squeeze()
        ds = merge_exp_ctrl(ds_ctrl, ds_exp)

        if "lev" in ds_ctrl.dims and vertical_sum == True:
            da_ctrl = ds[f"control_{vName}"].sum(dim="lev")
            da_exp = ds[vName].sum(dim="lev")
        elif "lev" in ds_ctrl.dims and vertical_sum == False:
            da_ctrl = ds[f"control_{vName}"]
            da_exp = ds[vName]
        else:
            da_ctrl = ds[f"control_{vName}"]
            da_exp = ds[vName]

        if "year" in da_ctrl.dims:
            t_dim = "year"
        else:
            t_dim = "time"

        if time_slice:
            da_ctrl = da_ctrl.isel({f"{t_dim}": time_slice})
            da_exp = da_exp.isel({f"{t_dim}": time_slice})
        if time_average:
            da_ctrl = da_ctrl.mean({f"{t_dim}": time_slice})
            da_exp = da_exp.mean({f"{t_dim}": time_slice})

        if rel_change:
            diff = ((da_exp - da_ctrl) / da_ctrl) * 100
            diff.attrs["units"] = "%"
            diff.attrs["long_name"] = "Relative change of {}".format(
                da_exp.attrs["long_name"]
            )
            diff = diff.to_dataset(name=vName)
            diff.attrs = {**diff.attrs, **ds_exp.attrs}
        else:
            diff = da_exp - da_ctrl
            diff.attrs[
                "long_name"
            ] = "Difference between experiment and control of {}".format(
                da_exp.attrs["long_name"]
            )
            diff = diff.to_dataset(name=vName)
            diff.attrs = {**diff.attrs, **ds_exp.attrs}
    return diff


def model_levels_to_pressure_levels(ds: xr.Dataset | xr.DataArray, 
                                    plevels=np.array([100000.,  92500.,  85000.,  70000.,  60000.,  50000.,  40000.,  30000.,
        25000.,  20000.,  15000.,  10000.,   7000.,   5000.,   3000.,   2000.,
         1000.,    500.,    100.])):
    """
    Convert model levels to pressure levels.
    """
    try:
        import geocat.comp as geocomp
    except ImportError:
        raise ImportError(
            "geocat-comp is required for this function. Run snakemake with --use-conda to enable it."
        )
    ds = ds.copy()
    if "ap" in ds.data_vars:
        ds = ds.rename_vars({"ap": "a"})

    if "lev_bounds" in ds.data_vars:
        ds = ds.rename_vars({"lev_bounds": "lev_bnds"})

    if isinstance(ds, xr.Dataset):
        da = ds[ds.variable_id].copy()
    else:
        da = ds.copy()
    if ds.cf["Z"].formula == "p = a*p0 + b*ps":
        if "a" in da.coords:
            da = da.drop("a")
        if "b" in da.coords:
            da = da.drop("b")
        if "ps" in da.coords:
            da = da.drop("ps")
        da = geocomp.interpolation.interp_hybrid_to_pressure(
            data=da,
            ps=ds["ps"],
            hyam=ds["a"],
            hybm=ds["b"],
            p0=ds.get("p0", 100000.0),
            new_levels=plevels
        )
    elif ds.cf["Z"].formula in ["p = ap + b*ps", "p(n,k,j,i) = ap(k) + b(k)*ps(n,j,i)"]:
        formula_terms = da.cf.formula_terms
        if "ap" in formula_terms or "ap" in ds.coords:
            hyam = ds["ap"]
            a = "ap"
        else:
            hyam = ds["a"]
            a = "a"

        if a in da.coords:
            da = da.drop(a)
        if "b" in da.coords:
            da = da.drop("b")
        if "ps" in da.coords:
            da = da.drop("ps")

        da = geocomp.interpolation.interp_hybrid_to_pressure(
            data=da, ps=ds["ps"], hyam=hyam, hybm=ds["b"], p0=ds.get("p0", 1),
            new_levels=plevels, lev_dim="lev"
        )

    else:
        print("formula not reconized")

    outds = da.to_dataset(name=ds.variable_id)
    outds.attrs = ds.attrs

    outds.attrs["history"] = (
        outds.attrs.get("history", "")
        + f"@{time.ctime()} converted to standard pressure levels"
    )
    return outds


def transelate_aerocom_helper(wildcards):
    if wildcards.freq == "2010":
        freq = "clim"
    elif wildcards.freq == "monthly":
        freq = "Amon"
    elif wildcards.freq == "yearly":
        freq = "Ayear"
    else:
        freq = wildcards.freq

    return freq


def read_list_input_paths(path_list: list, models_pos: int = -2):
    """
    Read a list of input paths and return a dictionary
    of models and corresponding datasets and the variable name.

    Parameters
    ----------
        path_list : list

    Returns
    -------
        out_dict : dict
        vname : str

    """
    models = {pst.split("_")[models_pos].split(".")[0]: pst for pst in path_list}
    out_dict = {}
    for model, path in models.items():
        try:
            ds = xr.open_dataset(path)
        except ValueError:
            ds = xr.open_dataset(path, decode_times=False)
            ds = ds.drop(["time_bnds"])
            ds = xr.decode_cf(ds)

        out_dict[model] = ds.copy()
    vname = ds.variable_id
    return out_dict, vname

def resample_time(data, variable_id=None):
    """
    Resample data to annual average
    
    """
    if variable_id is None:
        vname = data.variable_id
    else:
        vname = variable_id
    da = data[vname]
    variable_attrs = data[vname].attrs.copy()
    data_attrs = data.attrs.copy()
    
    coords_ds = data.copy()
    coords_ds = coords_ds.drop(['ps', vname, 'time','time_bnds','time_bounds'], errors='ignore')
    
    if da.units == 'kg m-2 s-1': # annual emission / deposition 
        da = da*365*24*60*60 # convert to kg m-2 yr-1
        da = da.resample(time='YE').mean()
        da.attrs = {**da.attrs, **variable_attrs}
        da.attrs['units'] = '{} year-1'.format(' '.join(data[vname].attrs['units'].split(' ')[:-1]))
        da.attrs['history'] = data.attrs.get('history', '') + f', annual average converted to kg m-2 yr-1'
    else:
        da=da.resample(time='YE').mean()
        da.attrs = {**da.attrs, **variable_attrs}
        # data[vname].attrs = attrs
        da.attrs['history'] = da.attrs.get('history','') + f', annual average'    


    out_ds = coords_ds.assign({vname: da})
    if 'ps' in data.data_vars or 'ps' in data.coords:
        with xr.set_options(keep_attrs=True):
            out_ds = out_ds.assign({'ps': data['ps'].resample(time='YE').mean()})

    out_ds.attrs = data_attrs

    return out_ds


def calculate_pooled_variance(da_ctrl, da_exp):
    """
    Calculate the pooled variance of two samples.

    Parameters
    ----------
        da_ctrl : xr.DataArray or np.ndarray
        da_exp : xr.DataArray or np.ndarray

    Returns
    -------
        pooled_var : float
    """

    n1 = len(da_ctrl)
    n2 = len(da_exp)
    var1 = np.var(da_ctrl)
    var2 = np.var(da_exp)
    pooled_var = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
    return pooled_var


def calculate_CI(
    da_ctrl: xr.DataArray or np.ndarray,
    da_exp: xr.DataArray or np.ndarray,
    alpha: float = 0.05,
    global_mean: bool = False,
    mask: xr.DataArray = None,
    weights: xr.DataArray = None,
):
    """
    Calculate the confidence interval of the difference between two samples.

    Parameters
    ----------
        da_ctrl : xr.DataArray or np.ndarray
        da_exp : xr.DataArray or np.ndarray
        alpha : float, optional
            Significance level, by default 0.05
        global_mean : bool, optional
            If True, calculate the global mean of the two samples, by default False
        mask : xr.DataArray, optional
            Mask to apply to the two samples, by default None
        weights : xr.DataArray, optional
            Weights to apply to the two samples, by default None

    Returns
    -------
        CI : tuple
            Confidence interval
        diff : float
            Difference between the two samples
    """
    from scipy.stats import t

    if global_mean:
        ctrlM = global_avg(da_ctrl)
        expM = global_avg(da_exp)
        diff = np.mean(da_exp) - np.mean(da_ctrl)
    elif mask is not None or weights is not None:
        ctrlM = masked_average(da_ctrl, mask=mask, weights=weights, dim=["lat", "lon"])
        expM = masked_average(da_exp, mask=mask, weights=weights, dim=["lat", "lon"])
        diff = expM.mean() - ctrlM.mean()

    else:
        ctrlM = da_ctrl.mean(dim=["lat", "lon"])
        expM = da_exp.mean(dim=["lat", "lon"])
        diff = expM.mean() - ctrlM.mean()

    pooled_var = calculate_pooled_variance(ctrlM, expM)
    std_err = np.sqrt(pooled_var) * np.sqrt(1 / len(ctrlM) + 1 / len(expM))
    t_value = t.ppf(1 - alpha / 2, len(ctrlM) + len(expM) - 2)
    CI = (diff - t_value * std_err, diff + t_value * std_err)
    return CI[0], CI[1], diff


def t_test_diff_sample_means(
    da_ctrl: xr.DataArray,
    da_exp: xr.DataArray,
    global_mean: bool = False,
    mask: xr.DataArray = None,
    weights: xr.DataArray = None,
    **test_kwargs
):
    """
    Perform a t-test for the difference between two samples.

    Parameters
    ----------
        da_ctrl : xr.DataArray or np.ndarray
            Control data
        da_exp : xr.DataArray or np.ndarray
            Experimental data
        global_mean : bool, optional
            If True, calculate the global mean, by default False
        mask : xr.DataArray, optional
            Mask to apply to the data, by default None
        weights : xr.DataArray, optional
            Weights to apply to the data, by default None

    Returns
    -------
        t_value : float
            t-value of the test
        p_value : float
            p-value of the test
        diff : float
            Difference between the two samples
    """
    from scipy.stats import ttest_ind

    # Calculate the global mean if requested
    if global_mean:
        ctrlM = global_avg(da_ctrl)
        expM = global_avg(da_exp)
        diff = global_avg(da_exp.mean(dim='time') - da_ctrl.mean(dim='time'))
    # Otherwise, apply a mask and weights if requested
    elif mask is not None or weights is not None:
        ctrlM = masked_average(da_ctrl, mask=mask, weights=weights, dim=["lat", "lon"])
        expM = masked_average(da_exp, mask=mask, weights=weights, dim=["lat", "lon"])
        diff = expM.mean() - ctrlM.mean()
    # Otherwise, just take the mean over all lat/lon
    elif "lon" not in da_ctrl.dims:
        ctrlM = da_ctrl
        expM = da_exp
        diff = da_exp.mean() - da_ctrl.mean()

    else:
        ctrlM = da_ctrl.mean(dim=["lat", "lon"])
        expM = da_exp.mean(dim=["lat", "lon"])
        diff = expM.mean() - ctrlM.mean()

    # Perform the t-test
    t_value, p_value = ttest_ind(expM, ctrlM, nan_policy='omit', **test_kwargs)
    return t_value, p_value, diff


def diff_means_greater_than_varability(
    da_ctrl: xr.DataArray,
    da_exp: xr.DataArray,
    global_mean: bool = False,
    mask: xr.DataArray = None,
    weights: xr.DataArray = None,
):
    """
    Check if the difference between two samples is greater than the variability of the samples.

    Parameters
    ----------
        da_ctrl : xr.DataArray or np.ndarray
        da_exp : xr.DataArray or np.ndarray
        global_mean : bool, optional
            If True, calculate the global mean of the samples, by default False
        mask : xr.DataArray, optional
            Mask to apply to the samples, by default None
        weights : xr.DataArray, optional
            Weights to apply to the samples, by default None

    Returns
    -------
        bool
    """
    if global_mean:
        ctrlM = global_avg(da_ctrl)
        expM = global_avg(da_exp)
        diff = np.mean(da_exp) - np.mean(da_ctrl)
    elif mask is not None or weights is not None:
        ctrlM = masked_average(da_ctrl, mask=mask, weights=weights, dim=["lat", "lon"])
        expM = masked_average(da_exp, mask=mask, weights=weights, dim=["lat", "lon"])
        diff = expM.mean() - ctrlM.mean()
    elif "lon" not in da_ctrl.dims:
        ctrlM = da_ctrl
        expM = da_exp
        diff = da_exp.mean() - da_ctrl.mean()
    
    else:
        ctrlM = da_ctrl.mean(dim=["lat", "lon"])
        expM = da_exp.mean(dim=["lat", "lon"])
        diff = expM.mean() - ctrlM.mean()

    pooled_var = calculate_pooled_variance(da_ctrl, da_exp)

    std_error =  np.sqrt(pooled_var)*np.sqrt((1/len(ctrlM)+1/len(expM)))
    t_val = diff/std_error
    return np.abs(diff) > np.sqrt(pooled_var), t_val


def masked_average(
    da: xr.DataArray, mask: xr.DataArray = None, weights: xr.DataArray = None, dim=None
):
    """
    Calculate the average of a DataArray over a mask.

    Parameters
    ----------
        da : xr.DataArray
        mask : xr.DataArray
        weights : xr.DataArray
        dim : str, optional

    Returns
    -------
        avg : float
    """
    da_copy = da.copy()
    if mask is not None:
        if mask.dtype == "bool":
            da_copy = da_copy.where(mask)
        else:
            da_copy = da_copy.where(mask.isnull() == False)
        if weights is not None:
            weights = weights.where(mask)
    if weights is not None:
        avg = da_copy.weighted(weights).mean(dim=dim)
    else:
        avg = da_copy.mean(dim=dim)

    return avg

def make_equal_dimmension(da: xr.DataArray, refrence_da: xr.DataArray, dim: str = "time"):
    """
    Make a DataArray have the same dimensions as a refrence DataArray.

    Parameters
    ----------
        da : xr.DataArray
        refrence_da : xr.DataArray
        dim : str, optional

    Returns
    -------
        da : xr.DataArray
    """
    da = da.copy()
    if dim not in da.dims:
        da = da.expand_dims(dim=dim)
    da = da.reindex_like(refrence_da)
    return da

def exponent(num):
    """Get exponent of input number

    Parameters
    ----------
    num : :obj:`float` or iterable
        input number

    Returns
    -------
    :obj:`int` or :obj:`ndarray` containing ints
        exponent of input number(s)

    Example
    -------
    >>> from pyaerocom.mathutils import exponent
    >>> exponent(2340)
    3
    """
    return np.floor(np.log10(abs(np.asarray(num)))).astype(int)
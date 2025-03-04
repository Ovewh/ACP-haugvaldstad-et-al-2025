import matplotlib
from cartopy.mpl.gridliner import LongitudeFormatter, LatitudeFormatter
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
from matplotlib.ticker import ScalarFormatter, AutoMinorLocator


def global_map(ax):
    # Set the map extent to global
    ax.set_extent([-180, 180, -90, 90], crs=ccrs.PlateCarree())

    # Set the major ticks on the map
    ax.set_xticks([-180, -120, -60, 0, 60, 120, 180], crs=ccrs.PlateCarree())
    ax.set_yticks([-90, -60, -30, 0, 30, 60, 90], crs=ccrs.PlateCarree())

    # Set the labels on the map
    lon_formatter = LongitudeFormatter(zero_direction_label=True)
    lat_formatter = LatitudeFormatter()
    ax.xaxis.set_major_formatter(lon_formatter)
    ax.yaxis.set_major_formatter(lat_formatter)

    # Set the minor ticks on the map
    ax.yaxis.set_minor_locator(AutoMinorLocator(3))
    ax.xaxis.set_minor_locator(AutoMinorLocator(2))

    # Add coastlines to the map
    ax.coastlines()

    # Remove the labels on the x and y axis
    ax.set_ylabel(" ")
    ax.set_xlabel(" ")

def create_facet_plot(
    nplots: int,
    figsize: tuple = None,
    subplot_kw: dict = {"projection": ccrs.PlateCarree()},
    last_axis_plain: bool = False,
    create_cax=True
):
    """
    Creates a facet plot with a certain number of plots. 
    """
    layout, default_figsize, cax_loc = _get_layouts(nplots)
    if not figsize:
        figsize = default_figsize
    fig, axes = plt.subplot_mosaic(layout, figsize=figsize, subplot_kw=subplot_kw)
    last = list(axes.keys())[-1]

    if last_axis_plain == True:
        pos = axes[last].get_position()
        axes[last] = fig.add_subplot(
            axes[last].get_gridspec().nrows, axes[last].get_gridspec().ncols, nplots
        )
    if create_cax:
        cax = fig.add_axes(cax_loc)
    else: 
        cax=None
    return fig, axes, cax


def _get_layouts(nplots: int):
    cax_loc = None
    figsize = None
    layout = ""
    if nplots == 1:
        layout = """
            A
            """
        figsize = (6, 5)
    elif nplots == 2:
        layout = """
            AB
            """
        figsize = (7, 2.8)
    elif nplots == 3:
        layout = """
            AABB
            .CC.
        """
        figsize = (8, 6)
    elif nplots == 4:
        layout = """
            AB
            CD
        """
        figsize = (8, 6)
    elif nplots == 5:
        layout = """
            AABB
            CCDD
            .EE.
        """
        figsize = (14, 12)
        cax_loc = [0.94,0.2,0.02,0.62]
    elif nplots == 6:
        layout = """
            AB
            CD
            EF
        """
        figsize = (14, 12)
        cax_loc = [0.94,0.2,0.02,0.62]
    elif nplots == 7:
        layout = """
            ABC
            DE.
            FG.
        """
        figsize = (16, 10)
        cax_loc = [0.94,0.2,0.02,0.62]
    elif nplots == 8:
        layout = """
            ABC
            DEF
            GH.
        """
        figsize = (16, 10)
        cax_loc = [0.94,0.2,0.02,0.62]
    elif nplots == 9:
        layout = """
            ABC
            DEF
            GHI
        """
        figsize = (16, 10)
        cax_loc = [0.94,0.2,0.02,0.62]
    elif nplots == 10:
        layout = """
            ABC
            DEF
            GHI
            LLL
        """
        figsize = (18, 14)
        cax_loc = [0.94,0.2,0.02,0.62]
    elif nplots == 11:
        layout = """
            ABC
            DEF
            GHI
            LLM
        
        """
    elif nplots == 12:
        layout = """
            ABCD
            EFGH
            ILMN
        """
    else:
        raise (NotImplementedError(f"Layout undefined for nplots = {nplots}"))
    if not cax_loc:
        cax_loc=[0.94,0.2,0.02,0.62]

    return layout, figsize, cax_loc


def get_model_colordict(opt=1):
    cdict = {
        'NorESM2-LM': '#9765ac',
        'MPI-ESM-1-2-HAM': '#ede76a', 
        'EC-Earth3-AerChem': '#4393cb', 
        'GISS-E2-1-G': '#c8884c',
        'UKESM1-0-LL': '#ad7e77', 
        'MIROC6': '#888b86',
        'IPSL-CM6A-LR-INCA': '#4c8657',
        'GFDL-ESM4': '#e0b892' ,
        'CNRM-ESM2-1':'#ff6347'
    }

    cdict2 = {
        'NorESM2-LM':'#6c8db1', 
        'MPI-ESM-1-2-HAM':'#ffc845',
        'EC-Earth3-AerChem':'#4fb17b',
        'GISS-E2-1-G':'#a1642d',
        'UKESM1-0-LL':'#857c7c',
        'MIROC6':'#d3568d', 
        'IPSL-CM6A-LR-INCA':'#6ba6a3', 
        'GFDL-ESM4':'#c18f5d', 
        'CNRM-ESM2-1':'#5b548e'


    }

    if opt==1: 
        return cdict
    elif opt==2:
        return cdict2
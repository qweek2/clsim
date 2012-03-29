from icecube.load_pybindings import load_pybindings
from icecube import icetray, dataclasses # be nice and pull in our dependencies
load_pybindings(__name__,__path__)


from MakeAntaresMediumProperties import GetPetzoldScatteringCosAngleDistribution, GetAntaresScatteringCosAngleDistribution, MakeAntaresMediumProperties
from MakeIceCubeMediumProperties import MakeIceCubeMediumProperties
from MakeIceCubeMediumPropertiesPhotonics import MakeIceCubeMediumPropertiesPhotonics
from GetIceCubeDOMAcceptance import GetIceCubeDOMAcceptance
from GetIceCubeDOMAngularSensitivity import GetIceCubeDOMAngularSensitivity
from GetIceCubeFlasherSpectrum import GetIceCubeFlasherSpectrum

from GetAntaresOMAcceptance import GetAntaresOMAcceptance
from GetAntaresOMAngularSensitivity import GetAntaresOMAngularSensitivity

from GetKM3NeTDOMAcceptance import GetKM3NeTDOMAcceptance

from FlasherInfoVectToFlasherPulseSeriesConverter import FlasherInfoVectToFlasherPulseSeriesConverter
from FakeFlasherInfoGenerator import FakeFlasherInfoGenerator

from GetDefaultParameterizationList import GetDefaultParameterizationList
from GetFlasherParameterizationList import GetFlasherParameterizationList
from AsyncTap import AsyncTap
from AutoSetGeant4Environment import AutoSetGeant4Environment

# import tray segments (if available)
from traysegments import I3CLSimMakeHits, I3CLSimMakePhotons, I3CLSimMakeHitsFromPhotons

# clean up the clsim namespace
del icetray
del dataclasses


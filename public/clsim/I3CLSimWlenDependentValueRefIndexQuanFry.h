#ifndef I3CLSIMWLENDEPENDENTVALUEREFINDEXQUANFRY_H_INCLUDED
#define I3CLSIMWLENDEPENDENTVALUEREFINDEXQUANFRY_H_INCLUDED

#include "clsim/I3CLSimWlenDependentValue.h"

#include <limits>

/**
 * @brief The phase refractive index of sea water according to a model
 * from Quan&Fry. The original model is taken from:
 * X. Quan, E.S. Fry, Appl. Opt., 34, 18 (1995) 3477-3480.
 *
 * An additional term describing pressure dependence was included according to:
 * Wolfgang H.W.A. Schuster, "Measurement of the Optical Properties of the Deep
 * Mediterranean - the ANTARES Detector Medium.",
 * PhD thesis (2002), St. Catherine's College, Oxford
 * downloaded Jan 2011 from: http://www.physics.ox.ac.uk/Users/schuster/thesis0098mmjhuyynh/thesis.ps
 */
static const unsigned i3clsimwlendependentvaluerefindexquanfry_version_ = 0;

struct I3CLSimWlenDependentValueRefIndexQuanFry : public I3CLSimWlenDependentValue
{
public:
    static const double default_salinity;
    static const double default_temperature;
    static const double default_pressure;
    static const double default_n0;
    static const double default_n1;
    static const double default_n2;
    static const double default_n3;
    static const double default_n4;
    static const double default_n5;
    static const double default_n6;
    static const double default_n7;
    static const double default_n8;
    static const double default_n9;
    static const double default_n10;
    
    
    I3CLSimWlenDependentValueRefIndexQuanFry(double salinity=default_salinity,       // fraction (e.g. 38*I3Units::perThousand)
                                             double temperature=default_temperature, // in degC
                                             double pressure=default_pressure,       // use I3Units (e.g. I3Units::bar)
                                             double n0  = default_n0,                // coefficients 0-10
                                             double n1  = default_n1,
                                             double n2  = default_n2,
                                             double n3  = default_n3,
                                             double n4  = default_n4,
                                             double n5  = default_n5,
                                             double n6  = default_n6,
                                             double n7  = default_n7,
                                             double n8  = default_n8,
                                             double n9  = default_n9,
                                             double n10 = default_n10
                                             );
    virtual ~I3CLSimWlenDependentValueRefIndexQuanFry();
    
    /**
     * If this is true, it is assumed that GetValue() and GetDerivative() return
     * meaningful values. If not, GetValue will not be called;
     * only the OpenCL implementation will be used.
     */
    virtual bool HasNativeImplementation() const {return true;};
    
    /**
     * If this is true, derivatives can be used.
     */
    virtual bool HasDerivative() const {return true;};
    
    /**
     * Shall return the value at a requested wavelength (n)
     */
    virtual double GetValue(double wlen) const;
    
    /**
     * Shall return the derivative at a requested wavelength (dn/dlambda)
     */
    virtual double GetDerivative(double wlen) const;
    
    /**
     * Shall return the minimal supported wavelength (possibly -inf)
     */
    virtual double GetMinWlen() const {return -std::numeric_limits<double>::infinity();}
    
    /**
     * Shall return the maximal supported wavelength (possibly +inf)
     */
    virtual double GetMaxWlen() const {return std::numeric_limits<double>::infinity();}
    
    /**
     * Shall return an OpenCL-compatible function named
     * functionName with a single float argument (float wlen)
     */
    virtual std::string GetOpenCLFunction(const std::string &functionName) const;
    
    /**
     * Shall return an OpenCL-compatible function named
     * functionName with a single float argument (float wlen)
     */
    virtual std::string GetOpenCLFunctionDerivative(const std::string &functionName) const;
    
    /**
     * Shall compare to another I3CLSimWlenDependentValue object
     */
    virtual bool CompareTo(const I3CLSimWlenDependentValue &other) const;
    
private:
    double salinity_;
    double temperature_;
    double pressure_;
    double n0_;
    double n1_;
    double n2_;
    double n3_;
    double n4_;
    double n5_;
    double n6_;
    double n7_;
    double n8_;
    double n9_;
    double n10_;
    
    // these can change even if the object is const
    mutable double a01;
    mutable double a2;
    mutable double a3;
    mutable double a4;
    void UpdateMutables() const;

    
    friend class boost::serialization::access;
    template <class Archive> void serialize(Archive & ar, unsigned version);
};


BOOST_CLASS_VERSION(I3CLSimWlenDependentValueRefIndexQuanFry, i3clsimwlendependentvaluerefindexquanfry_version_);

I3_POINTER_TYPEDEFS(I3CLSimWlenDependentValueRefIndexQuanFry);

#endif //I3CLSIMWLENDEPENDENTVALUEREFINDEXQUANFRY_H_INCLUDED

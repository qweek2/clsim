#ifndef I3CLSIMSIMPLEGEOMETRYUSERCONFIGURABLE_H_INCLUDED
#define I3CLSIMSIMPLEGEOMETRYUSERCONFIGURABLE_H_INCLUDED

#include "clsim/I3CLSimSimpleGeometry.h"

/**
 * @brief Describes a detector geometry.
 *
 * The DOM properties have to be explicitly set by the user.
 */

class I3CLSimSimpleGeometryUserConfigurable : public I3CLSimSimpleGeometry
{
    
public:
    I3CLSimSimpleGeometryUserConfigurable(double OMRadius, std::size_t numOMs);
    ~I3CLSimSimpleGeometryUserConfigurable();

    virtual std::size_t size() const {return numOMs_;}

    virtual double GetOMRadius() const {return OMRadius_;}
    
    virtual const std::vector<int32_t> &GetStringIDVector() const {return stringIDs_;}
    virtual const std::vector<uint32_t> &GetDomIDVector() const {return domIDs_;}
    virtual const std::vector<double> &GetPosXVector() const {return posX_;}
    virtual const std::vector<double> &GetPosYVector() const {return posY_;}
    virtual const std::vector<double> &GetPosZVector() const {return posZ_;}

    virtual int32_t GetStringID(std::size_t pos) const {return stringIDs_.at(pos);}
    virtual uint32_t GetDomID(std::size_t pos) const {return domIDs_.at(pos);}
    virtual double GetPosX(std::size_t pos) const {return posX_.at(pos);}
    virtual double GetPosY(std::size_t pos) const {return posY_.at(pos);}
    virtual double GetPosZ(std::size_t pos) const {return posZ_.at(pos);}
    
    
    // additional methods
    virtual void SetStringID(std::size_t pos, int32_t val) {stringIDs_.at(pos) = val;}
    virtual void SetDomID(std::size_t pos, uint32_t val) {domIDs_.at(pos) = val;}
    virtual void SetPosX(std::size_t pos, double val) {posX_.at(pos) = val;}
    virtual void SetPosY(std::size_t pos, double val) {posY_.at(pos) = val;}
    virtual void SetPosZ(std::size_t pos, double val) {posZ_.at(pos) = val;}

    
private:
    double OMRadius_;
    std::size_t numOMs_;
    
    std::vector<int32_t> stringIDs_;
    std::vector<uint32_t> domIDs_;
    std::vector<double> posX_;
    std::vector<double> posY_;
    std::vector<double> posZ_;
};

I3_POINTER_TYPEDEFS(I3CLSimSimpleGeometryUserConfigurable);

#endif //I3CLSIMSIMPLEGEOMETRYUSERCONFIGURABLE_H_INCLUDED

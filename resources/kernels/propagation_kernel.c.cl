


#ifdef DOUBLE_PRECISION
// can't have native_math with double precision
#ifdef USE_NATIVE_MATH
#undef USE_NATIVE_MATH
#endif
#endif

#ifdef USE_NATIVE_MATH
inline floating_t my_divide(floating_t a, floating_t b) {return native_divide(a,b);}
inline floating_t my_recip(floating_t a) {return native_recip(a);}
inline floating_t my_powr(floating_t a, floating_t b) {return native_powr(a,b);}
inline floating_t my_sqrt(floating_t a) {return native_sqrt(a);}
inline floating_t my_rsqrt(floating_t a) {return native_rsqrt(a);}
inline floating_t my_cos(floating_t a) {return native_cos(a);}
inline floating_t my_sin(floating_t a) {return native_sin(a);}
inline floating_t my_log(floating_t a) {return native_log(a);}
inline floating_t my_exp(floating_t a) {return native_exp(a);}
#else
inline floating_t my_divide(floating_t a, floating_t b) {return a/b;}
inline floating_t my_recip(floating_t a) {return 1.f/a;}
inline floating_t my_powr(floating_t a, floating_t b) {return powr(a,b);}
inline floating_t my_sqrt(floating_t a) {return sqrt(a);}
inline floating_t my_rsqrt(floating_t a) {return rsqrt(a);}
inline floating_t my_cos(floating_t a) {return cos(a);}
inline floating_t my_sin(floating_t a) {return sin(a);}
inline floating_t my_log(floating_t a) {return log(a);}
inline floating_t my_exp(floating_t a) {return exp(a);}
#endif

#ifdef USE_FABS_WORKAROUND
inline floating_t my_fabs(floating_t a) {return (a<ZERO)?(-a):(a);}
#else
inline floating_t my_fabs(floating_t a) {return fabs(a);}
#endif
inline floating_t sqr(floating_t a) {return a*a;}




inline int findLayerForGivenZPos(floating_t posZ)
{
    return convert_int((posZ-(floating_t)MEDIUM_LAYER_BOTTOM_POS)/(floating_t)MEDIUM_LAYER_THICKNESS);
}

inline floating_t mediumLayerBoundary(int layer)
{
    return (convert_floating_t(layer)*((floating_t)MEDIUM_LAYER_THICKNESS)) + (floating_t)MEDIUM_LAYER_BOTTOM_POS;
}

void scatterDirectionByAngle(floating_t cosa,
    floating_t sina,
    floating4_t *direction,
    floating_t randomNumber)
{
    //printf("direction before=(%f,%f,%f) len^2=%f  -> cos=%f, sin=%f, r=%f\n",
    //       (*direction).x, (*direction).y, (*direction).z,
    //       (*direction).x*(*direction).x + (*direction).y*(*direction).y + (*direction).z*(*direction).z,
    //       cosa, sina, randomNumber);

    // randomize direction of scattering (rotation around old direction axis)
#ifdef DOUBLE_PRECISION
    const floating_t b=2.0*PI*randomNumber;
#else
    const floating_t b=2.0f*PI*randomNumber;
#endif
    const floating_t cosb=my_cos(b);
    const floating_t sinb=my_sin(b);

    // Rotate new direction into absolute frame of reference 
    const floating_t sinth = my_sqrt(max(ZERO, ONE-(*direction).z*(*direction).z));
    
    if(sinth>0.f){  // Current direction not vertical, so rotate 
        const floating4_t oldDir = *direction;

        (*direction).x=oldDir.x*cosa-my_divide((oldDir.y*cosb+oldDir.z*oldDir.x*sinb)*sina,sinth);
        (*direction).y=oldDir.y*cosa+my_divide((oldDir.x*cosb-oldDir.z*oldDir.y*sinb)*sina,sinth);
        (*direction).z=oldDir.z*cosa+sina*sinb*sinth;
    }else{         // Current direction is vertical, so this is trivial
        (*direction).x=sina*cosb;
        (*direction).y=sina*sinb;
        (*direction).z=cosa*sign((*direction).z);
    }

    {
        const floating_t recip_length = my_rsqrt(sqr((*direction).x) + sqr((*direction).y) + sqr((*direction).z));

        (*direction).x *= recip_length;
        (*direction).y *= recip_length;
        (*direction).z *= recip_length;
    }

    //printf("direction after=(%f,%f,%f) len^2=%f\n",
    //       (*direction).x, (*direction).y, (*direction).z,
    //       (*direction).x*(*direction).x + (*direction).y*(*direction).y + (*direction).z*(*direction).z);

}


inline void createPhotonFromTrack(struct I3CLSimStep *step,
    const floating4_t stepDir,
    RNG_ARGS,
    floating4_t *photonPosAndTime,
    floating4_t *photonDirAndWlen)
{
    floating_t shiftMultiplied = step->dirAndLengthAndBeta.z*RNG_CALL_UNIFORM_CO;
    floating_t inverseParticleSpeed = my_recip(speedOfLight*step->dirAndLengthAndBeta.w);

    // move along the step direction
    *photonPosAndTime = (floating4_t)
        (
        step->posAndTime.x+stepDir.x*shiftMultiplied,
        step->posAndTime.y+stepDir.y*shiftMultiplied,
        step->posAndTime.z+stepDir.z*shiftMultiplied,
        step->posAndTime.w+inverseParticleSpeed*shiftMultiplied
        );

    // determine the photon layer (clamp if necessary)
    unsigned int layer = min(max(findLayerForGivenZPos( (*photonPosAndTime).z ), 0), MEDIUM_LAYERS-1);

#ifndef NO_FLASHER
    if (step->sourceType == 0) {
#endif
        // sourceType==0 is always Cherenkov light with the correct angle w.r.t. the particle/step
        
        // our photon still needs a wavelength. create one!
        const floating_t wavelength = generateWavelength_0(RNG_ARGS_TO_CALL);

        const floating_t cosCherenkov = my_recip(step->dirAndLengthAndBeta.w*getPhaseRefIndex(layer, wavelength)); // cos theta = 1/(beta*n)
        const floating_t sinCherenkov = my_sqrt(ONE-cosCherenkov*cosCherenkov);
        // determine the photon direction

        // start with the track direction
        (*photonDirAndWlen).xyz = stepDir.xyz;
        (*photonDirAndWlen).w = wavelength;

        // and now rotate to cherenkov emission direction
        //printf("gen:\n");
        scatterDirectionByAngle(cosCherenkov, sinCherenkov, photonDirAndWlen, RNG_CALL_UNIFORM_CO);
        //printf("endgen.\n");
#ifndef NO_FLASHER
    } else {
        // steps >= 1 are flasher emissions, they do not need cherenkov rotation
        
        const floating_t wavelength = generateWavelength(convert_uint(step->sourceType), RNG_ARGS_TO_CALL);
        
        // use the step direction as the photon direction
        (*photonDirAndWlen).xyz = stepDir.xyz;
        (*photonDirAndWlen).w = wavelength;
    }
#endif
}

#ifdef DOUBLE_PRECISION
inline float2 sphDirFromCar(double4 carDir)
{
    // Calculate Spherical coordinates from Cartesian
    const double r_inv = my_rsqrt(carDir.x*carDir.x+carDir.y*carDir.y+carDir.z*carDir.z);

    double theta = 0.;
    if ((my_fabs(carDir.z*r_inv))<=1.) {
        theta=acos(carDir.z*r_inv);
    } else {
        if (carDir.z<0.) theta=PI;
    }
    if (theta<0.) theta+=2.*PI;

    double phi=atan2(carDir.y,carDir.x);
    if (phi<0.) phi+=2.*PI;

    return (float2)(theta, phi);
}
#else
inline float2 sphDirFromCar(float4 carDir)
{
    // Calculate Spherical coordinates from Cartesian
    const float r_inv = my_rsqrt(carDir.x*carDir.x+carDir.y*carDir.y+carDir.z*carDir.z);

    float theta = 0.f;
    if ((my_fabs(carDir.z*r_inv))<=1.f) {
        theta=acos(carDir.z*r_inv);
    } else {
        if (carDir.z<0.f) theta=PI;
    }
    if (theta<0.f) theta+=2.f*PI;

    float phi=atan2(carDir.y,carDir.x);
    if (phi<0.f) phi+=2.f*PI;

    return (float2)(theta, phi);
}
#endif

// Record a photon on a DOM
inline void saveHit(
    const floating4_t photonPosAndTime,
    const floating4_t photonDirAndWlen,
    const floating_t thisStepLength,
    floating_t inv_groupvel,
    floating_t photonTotalPathLength,
    uint photonNumScatters,
    const floating4_t photonStartPosAndTime,
    const floating4_t photonStartDirAndWlen,
    const struct I3CLSimStep *step,
    unsigned short hitOnString,
    unsigned short hitOnDom,
    __global uint* hitIndex,
    uint maxHitIndex,
    __write_only __global struct I3CLSimPhoton *outputPhotons
    )
{
    uint myIndex = atom_inc(hitIndex);
    if (myIndex < maxHitIndex)
    {
#ifdef PRINTF_ENABLED
        dbg_printf("     -> photon record added at position %u.\n",
            myIndex);
#endif

        outputPhotons[myIndex].posAndTime = (float4)
            (
            photonPosAndTime.x+thisStepLength*photonDirAndWlen.x,
            photonPosAndTime.y+thisStepLength*photonDirAndWlen.y,
            photonPosAndTime.z+thisStepLength*photonDirAndWlen.z,
            photonPosAndTime.w+thisStepLength*inv_groupvel
            );

        outputPhotons[myIndex].dir = sphDirFromCar(photonDirAndWlen);
        outputPhotons[myIndex].wavelength = photonDirAndWlen.w;

        outputPhotons[myIndex].cherenkovDist = photonTotalPathLength+thisStepLength;
        outputPhotons[myIndex].numScatters = photonNumScatters;
        outputPhotons[myIndex].weight = step->weight / getWavelengthBias(photonDirAndWlen.w);
        outputPhotons[myIndex].identifier = step->identifier;

        outputPhotons[myIndex].stringID = convert_short(hitOnString);
        outputPhotons[myIndex].omID = convert_ushort(hitOnDom);

#ifdef DOUBLE_PRECISION
        outputPhotons[myIndex].startPosAndTime=(float4)(photonStartPosAndTime.x, photonStartPosAndTime.y, photonStartPosAndTime.z, photonStartPosAndTime.w);
#else
        outputPhotons[myIndex].startPosAndTime=photonStartPosAndTime;
#endif
        outputPhotons[myIndex].startDir = sphDirFromCar(photonStartDirAndWlen);

        outputPhotons[myIndex].groupVelocity = my_recip(inv_groupvel);


#ifdef PRINTF_ENABLED
        dbg_printf("     -> stored photon: p=(%f,%f,%f), d=(%f,%f), t=%f, wlen=%fnm\n",
            outputPhotons[myIndex].posAndTime.x, outputPhotons[myIndex].posAndTime.y, outputPhotons[myIndex].posAndTime.z,
            outputPhotons[myIndex].dir.x, outputPhotons[myIndex].dir.y,
            outputPhotons[myIndex].posAndTime.w, outputPhotons[myIndex].wavelength/1e-9f);
#endif

    }
    
    
}

__kernel void propKernel(__global uint *hitIndex,   // deviceBuffer_CurrentNumOutputPhotons
    const uint maxHitIndex,    // maxNumOutputPhotons_
    __read_only __global unsigned short *geoLayerToOMNumIndexPerStringSet,

    __read_only __global struct I3CLSimStep *inputSteps, // deviceBuffer_InputSteps
    __write_only __global struct I3CLSimPhoton *outputPhotons, // deviceBuffer_OutputPhotons

#ifdef SAVE_PHOTON_HISTORY
    __write_only __global float4 *photonHistory,
#endif

    __global ulong* MWC_RNG_x,
    __global uint* MWC_RNG_a)
{
    unsigned int i = get_global_id(0);

#ifdef PRINTF_ENABLED
    unsigned int global_size = get_global_size(0);
    dbg_printf("Start kernel... (work item %u of %u)\n", i, global_size);
#endif

    __local unsigned short geoLayerToOMNumIndexPerStringSetLocal[GEO_geoLayerToOMNumIndexPerStringSet_BUFFER_SIZE];

    // copy the geo data to our local memory (this is done by a whole work group in parallel)
    event_t copyFinishedEvent =
        async_work_group_copy(geoLayerToOMNumIndexPerStringSetLocal,
        geoLayerToOMNumIndexPerStringSet, 
        (size_t)GEO_geoLayerToOMNumIndexPerStringSet_BUFFER_SIZE,
        0);
    wait_group_events(1, &copyFinishedEvent);
    //barrier(CLK_LOCAL_MEM_FENCE);


    //download MWC RNG state
    ulong real_rnd_x = MWC_RNG_x[i];
    uint real_rnd_a = MWC_RNG_a[i];
    ulong *rnd_x = &real_rnd_x;
    uint *rnd_a = &real_rnd_a;

    // download the step
    struct I3CLSimStep step;
    step.posAndTime = inputSteps[i].posAndTime;
    step.dirAndLengthAndBeta = inputSteps[i].dirAndLengthAndBeta;
    step.numPhotons = inputSteps[i].numPhotons;
    step.weight = inputSteps[i].weight;
    step.identifier = inputSteps[i].identifier;
#ifndef NO_FLASHER
    // only needed for flashers
    step.sourceType = inputSteps[i].sourceType;
#endif
    //step.dummy1 = inputSteps[i].dummy1;  // NOT USED
    //step.dummy2 = inputSteps[i].dummy2;  // NOT USED
    //step = inputSteps[i]; // Intel OpenCL does not like this

    floating4_t stepDir;
    {
        const floating_t rho = my_sin(step.dirAndLengthAndBeta.x); // sin(theta)
        stepDir = (floating4_t)(rho*my_cos(step.dirAndLengthAndBeta.y), // rho*cos(phi)
            rho*my_sin(step.dirAndLengthAndBeta.y), // rho*sin(phi)
            my_cos(step.dirAndLengthAndBeta.x),    // cos(phi)
            ZERO);
    }

#ifdef PRINTF_ENABLED
    dbg_printf("Step at: p=(%f,%f,%f), d=(%f,%f,%f), t=%f, l=%f, N=%u\n",
        step.posAndTime.x,
        step.posAndTime.y,
        step.posAndTime.z,
        stepDir.x, stepDir.y, stepDir.z,
        step.posAndTime.w,
        step.dirAndLengthAndBeta.z,
        step.numPhotons);
#endif

#ifdef DOUBLE_PRECISION
    #define EPSILON 0.00000001
#else
    #define EPSILON 0.00001f
#endif

    uint photonsLeftToPropagate=step.numPhotons;
    floating_t abs_lens_left=ZERO;
    
    floating4_t photonStartPosAndTime;
    floating4_t photonStartDirAndWlen;
    floating4_t photonPosAndTime;
    floating4_t photonDirAndWlen;
    uint photonNumScatters=0;
    floating_t photonTotalPathLength=ZERO;
    int currentPhotonLayer=0;

#ifndef FUNCTION_getGroupVelocity_DOES_NOT_DEPEND_ON_LAYER
#error This kernel only works with a constant group velocity (constant w.r.t. layers)
#endif
    floating_t inv_groupvel=ZERO;


    while (photonsLeftToPropagate > 0)
    {
        if (abs_lens_left < EPSILON)
        {
            // create a new photon
            createPhotonFromTrack(&step,
                stepDir,
                RNG_ARGS_TO_CALL,
                &photonPosAndTime,
                &photonDirAndWlen);
            
            // save the start position and time
            photonStartPosAndTime=photonPosAndTime;
            photonStartDirAndWlen=photonDirAndWlen;
            
            photonNumScatters=0;
            photonTotalPathLength=ZERO;
            
#ifdef PRINTF_ENABLED
            dbg_printf("   created photon %u at: p=(%f,%f,%f), d=(%f,%f,%f), t=%f, wlen=%fnm\n",
                photonsLeftToPropagate-step.numPhotons,
                photonPosAndTime.x, photonPosAndTime.y, photonPosAndTime.z,
                photonDirAndWlen.x, photonDirAndWlen.y, photonDirAndWlen.z,
                photonPosAndTime.w, photonDirAndWlen.w/1e-9f);
#endif
            
            currentPhotonLayer = min(max(findLayerForGivenZPos(photonPosAndTime.z), 0), MEDIUM_LAYERS-1);
            //currentPhotonLayer = findLayerForGivenZPos(photonPosAndTime.z);
#ifdef PRINTF_ENABLED
            dbg_printf("   in layer %i (valid between 0 and up to including %u)\n", currentPhotonLayer, MEDIUM_LAYERS-1);
#endif
            
            inv_groupvel = my_recip(getGroupVelocity(0, photonDirAndWlen.w));
            
            // the photon needs a lifetime. determine distance to next scatter and absorption
            // (this is in units of absorption/scattering lengths)
            abs_lens_left = -my_log(RNG_CALL_UNIFORM_OC);
            
            //if ((currentPhotonLayer < 0) || (currentPhotonLayer >= MEDIUM_LAYERS)) abs_lens_left=0.f; // outside, do not track
            
#ifdef PRINTF_ENABLED
            dbg_printf("   - total track length will be %f absorption lengths\n", abs_lens_left);
#endif
        }

        // this block is along the lines of the PPC kernel
        floating_t distancePropagated;
        {
            const floating_t photon_dz=photonDirAndWlen.z;
            
            // the "next" medium boundary (either top or bottom, depending on step direction)
            floating_t mediumBoundary = (photon_dz<ZERO)?(mediumLayerBoundary(currentPhotonLayer)):(mediumLayerBoundary(currentPhotonLayer)+(floating_t)MEDIUM_LAYER_THICKNESS);

            // track this thing to the next scattering point
            floating_t sca_step_left = -my_log(RNG_CALL_UNIFORM_OC);
#ifdef PRINTF_ENABLED
            dbg_printf("   - next scatter in %f scattering lengths\n", sca_step_left);
#endif
            
            floating_t currentScaLen = getScatteringLength(currentPhotonLayer, photonDirAndWlen.w);
            floating_t currentAbsLen = getAbsorptionLength(currentPhotonLayer, photonDirAndWlen.w);
            
            floating_t ais=( photon_dz*sca_step_left - my_divide((mediumBoundary-photonPosAndTime.z),currentScaLen) )*(ONE/(floating_t)MEDIUM_LAYER_THICKNESS);
            floating_t aia=( photon_dz*abs_lens_left - my_divide((mediumBoundary-photonPosAndTime.z),currentAbsLen) )*(ONE/(floating_t)MEDIUM_LAYER_THICKNESS);

#ifdef PRINTF_ENABLED
            dbg_printf("   - ais=%f, aia=%f, j_initial=%i\n", ais, aia, currentPhotonLayer);
#endif
        
            // propagate through layers
            int j=currentPhotonLayer;
            if(photon_dz<0) {
                for (; (j>0) && (ais<ZERO) && (aia<ZERO); 
                     mediumBoundary-=(floating_t)MEDIUM_LAYER_THICKNESS,
                     currentScaLen=getScatteringLength(j, photonDirAndWlen.w),
                     currentAbsLen=getAbsorptionLength(j, photonDirAndWlen.w),
                     ais+=my_recip(currentScaLen),
                     aia+=my_recip(currentAbsLen)) --j;
            } else {
                for (; (j<MEDIUM_LAYERS-1) && (ais>ZERO) && (aia>ZERO);
                     mediumBoundary+=(floating_t)MEDIUM_LAYER_THICKNESS,
                     currentScaLen=getScatteringLength(j, photonDirAndWlen.w),
                     currentAbsLen=getAbsorptionLength(j, photonDirAndWlen.w),
                     ais-=my_recip(currentScaLen),
                     aia-=my_recip(currentAbsLen)) ++j;
            }
        
#ifdef PRINTF_ENABLED
            dbg_printf("   - j_final=%i\n", j);
#endif
        
            floating_t distanceToAbsorption;
            if ((currentPhotonLayer==j) || ((my_fabs(photon_dz))<EPSILON)) {
                distancePropagated=sca_step_left*currentScaLen;
                distanceToAbsorption=abs_lens_left*currentAbsLen;
            } else {
                const floating_t recip_photon_dz = my_recip(photon_dz);
                distancePropagated=(ais*((floating_t)MEDIUM_LAYER_THICKNESS)*currentScaLen+mediumBoundary-photonPosAndTime.z)*recip_photon_dz;
                distanceToAbsorption=(aia*((floating_t)MEDIUM_LAYER_THICKNESS)*currentAbsLen+mediumBoundary-photonPosAndTime.z)*recip_photon_dz;
            }
            currentPhotonLayer=j;
            
#ifdef PRINTF_ENABLED
            dbg_printf("   - distancePropagated=%f\n", distancePropagated);
#endif
        
            // get overburden for distance
            if (distanceToAbsorption<distancePropagated) {
                distancePropagated=distanceToAbsorption;
                abs_lens_left=ZERO;
            } else {
                abs_lens_left=my_divide(distanceToAbsorption-distancePropagated, currentAbsLen);
            }
        }

        // the photon is now either being absorbed or scattered.
        // Check for collisions in its way
#ifdef STOP_PHOTONS_ON_DETECTION
#ifdef DEBUG_STORE_GENERATED_PHOTONS
        bool collided;
        if (RNG_CALL_UNIFORM_OC > 0.9)  // prescale: 10%
#else
        bool
#endif
        collided = 
#endif
        checkForCollision(photonPosAndTime, 
            photonDirAndWlen, 
            inv_groupvel,
            photonTotalPathLength,
            photonNumScatters,
            photonStartPosAndTime,
            photonStartDirAndWlen,
            &step,
#ifdef STOP_PHOTONS_ON_DETECTION
            &distancePropagated, 
#else
            distancePropagated, 
#endif
            hitIndex, 
            maxHitIndex, 
            outputPhotons, 
            geoLayerToOMNumIndexPerStringSetLocal
            );
            
#ifdef STOP_PHOTONS_ON_DETECTION
#ifdef DEBUG_STORE_GENERATED_PHOTONS
        collided = true;
#endif
        if (collided) {
            // get rid of the photon if we detected it
            abs_lens_left = ZERO;

#ifdef PRINTF_ENABLED
            dbg_printf("    . colission detected, step limited to thisStepLength=%f!\n", 
                distancePropagated);
#endif
        }
#endif
        
        // update the track to its next position
        photonPosAndTime.x += photonDirAndWlen.x*distancePropagated;
        photonPosAndTime.y += photonDirAndWlen.y*distancePropagated;
        photonPosAndTime.z += photonDirAndWlen.z*distancePropagated;
        photonPosAndTime.w += inv_groupvel*distancePropagated;
        photonTotalPathLength += distancePropagated;


        // absorb or scatter the photon
        if (abs_lens_left < EPSILON) 
        {
            // photon was absorbed.
            // a new one will be generated at the begin of the loop.
            --photonsLeftToPropagate;
        }
        else
        {
            // photon was NOT absorbed. scatter it and re-start the loop
            
            // calculate a new direction
#ifdef PRINTF_ENABLED
            dbg_printf("   - photon is not yet absorbed (abs_len_left=%f)! Scattering!\n", abs_lens_left);
#endif

#ifdef PRINTF_ENABLED
            dbg_printf("    . photon direction before: d=(%f,%f,%f), wlen=%f\n",
                photonDirAndWlen.x, photonDirAndWlen.y, photonDirAndWlen.z,
                photonDirAndWlen.w/1e-9f);
#endif

            const floating_t cosScatAngle = makeScatteringCosAngle(RNG_ARGS_TO_CALL);
            const floating_t sinScatAngle = my_sqrt(ONE - sqr(cosScatAngle));

            scatterDirectionByAngle(cosScatAngle, sinScatAngle, &photonDirAndWlen, RNG_CALL_UNIFORM_CO);

#ifdef PRINTF_ENABLED
            dbg_printf("    . cos(scat_angle)=%f sin(scat_angle)=%f\n",
                cosScatAngle, sinScatAngle);
#endif

#ifdef PRINTF_ENABLED
            dbg_printf("    . photon direction after:  d=(%f,%f,%f), wlen=%f\n",
                photonDirAndWlen.x, photonDirAndWlen.y, photonDirAndWlen.z,
                photonDirAndWlen.w/1e-9f);
#endif

            ++photonNumScatters;

#ifdef PRINTF_ENABLED
            dbg_printf("    . the photon has now been scattered %u time(s).\n", photonNumScatters);
#endif
        }


    }

#ifdef PRINTF_ENABLED
    dbg_printf("Stop kernel... (work item %u of %u)\n", i, global_size);
    dbg_printf("Kernel finished.\n");
#endif

    //upload MWC RNG state
    MWC_RNG_x[i] = real_rnd_x;
    MWC_RNG_a[i] = real_rnd_a;
}
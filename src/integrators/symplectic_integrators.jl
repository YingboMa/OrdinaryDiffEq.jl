@inline function initialize!(integrator,cache::SymplecticEulerCache,f=integrator.f)
  integrator.kshortsize = 2
  @unpack k,fsalfirst = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.k = eltype(integrator.sol.k)(integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  # Do the calculation pre
  # So that way FSAL interpolation
  uprev,duprev = integrator.uprev.x
  u,du = integrator.u.x
  ku = integrator.k[1].x[1]
  kdu = integrator.k[2].x[2]
  f[2](integrator.t,uprev,duprev,kdu)
  dt = integrator.dt
  #du = muladd.(integrator.dt,kdu,duprev)
  duidx = eachindex(du)
  @tight_loop_macros for i in duidx
    @inbounds du[i] = muladd(dt,kdu[i],duprev[i])
  end
  f[1](integrator.t,uprev,du,ku)
end

@inline function perform_step!(integrator,cache::SymplecticEulerCache,f=integrator.f)
  @unpack t,dt = integrator
  uprev,duprev = integrator.uprev.x
  u,du = integrator.u.x
  duidx = eachindex(du)
  uidx = eachindex(u)
  kuprev = integrator.k[1].x[1]
  ku  = integrator.k[2].x[1]
  kdu = integrator.k[2].x[2]
  #u .= muladd.(dt,kuprev,uprev)
  @tight_loop_macros for i in uidx
    @inbounds u[i] = muladd(dt,kuprev[i],uprev[i])
  end
  # Now actually compute the step
  # Do it at the end for interpolations!
  f[2](integrator.t,uprev,duprev,kdu)
  #du .= muladd.(dt,kdu,duprev)
  @tight_loop_macros for i in duidx
    du[i] = muladd(dt,kdu[i],duprev[i])
  end
  f[1](integrator.t,uprev,du,ku)
end

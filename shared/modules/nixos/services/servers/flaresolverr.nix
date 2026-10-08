#=====================================================================#
# FLARESOLVERR CLOUDFLARE SOLVER
#=====================================================================#
#- Solves Cloudflare challenges for Moku's Tsunagu backend. In Moku, set
#- Server → Cloudflare solver to External; its default Solver URL,
#- http://127.0.0.1:8191, matches the port here. Firewall stays closed.
{
  #--------------------------------------------------------------------#
  #-- FlareSolverr
  #--------------------------------------------------------------------#
  services.flaresolverr.enable = true;
}

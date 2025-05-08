@info "GETTING INPUT FROM USER"
print("Sequence folder (ex: ../sequences/Pulseq/): ")
seqFolder = readline()
print("Sequence to simulate (do not include .seq): ")
radical = readline()
print("Phantom to use (cylinder or brain): ")
pantom_choice = readline()
@info "GETTING INPUT FROM USER... done."

@info "Loading packages..."
using KomaMRI
using CUDA
using MAT
@info "Loading packages... done."

@info "Preparing phantoms..."
function check_phantom_arguments(nd, ss, us)
     # check for valid input    
     ssx = -9999
     ssz = -9999
     usz = -9999
     if length(us) > 1 || prod(us) > 1
        #  @info "setting ss=1 since us=$(us) defined"
         ss = 1
     end
     if nd == 3
         @assert length(ss) <= 3 "ss=$(ss) invalid, ss can have up to three components [ssx, ssy, ssz] for a 3D phantom"
         @assert length(us) <= 3 "us=$(us) invalid, us can have up to three components [usx, usy, usz] for a 3D phantom"
         if length(us) == 1
             usx = us[1]
             usy = us[1]
             usz = us[1]
         elseif length(us) == 2
             usx = us[1]
             usy = us[2]
             usz = us[2]
             @warn "Using us=$([usx, usy, usz]) in place of us=$([usx, usy])."
         else
             usx = us[1]
             usy = us[2]
             usz = us[3]
         end
         if length(ss) == 1
             ssx = ss[1]
             ssy = ss[1]
             ssz = ss[1]
         elseif length(ss) == 2
             ssx = ss[1]
             ssy = ss[2]
             ssz = ss[2]
             @warn "Using ss=$([ssx, ssy, ssz]) in place of ss=$([ssx, ssy])."
         else
             ssx = ss[1]
             ssy = ss[2]
             ssz = ss[3]
         end
     elseif nd == 2
         @assert length(ss) <= 2 "ss=$(ss) invalid, ss can have up to two components [ssx, ssy] for a 2D phantom"
         @assert length(us) <= 2 "us=$(us) invalid, us can have up to two components [usx, usy] for a 2D phantom"
         if length(us) == 1
             usx = us[1]
             usy = us[1]
         else
             usx = us[1]
             usy = us[2]
         end
         if length(ss) == 1
             ssx = ss[1]
             ssy = ss[1]
         else
             ssx = ss[1]
             ssy = ss[2]
         end
     end
     return ssx, ssy, ssz, usx, usy, usz
 end

# For MAT files
ss = 1
us = 3 # 3 For spoilers
# us = 1
ssx, ssy, ssz, usx, usy, usz = check_phantom_arguments(2, ss, us)

structureFileName = "Inhomogeneous_cylindrical_phantom.mat";
structure = MAT.matread(structureFileName);
voxelSize = structure["res"];
slice = repeat(structure["Compartment_mask"][1:ssx:end, 1:ssy:end, 50]; inner=[usx, usy]);

# Plot selected slice
# plot_image(slice)

# Define spin position arrays
Δx = 1.96e-3 * ssx / usx
Δy = 1.96e-3 * ssy / usy
M, N = size(slice)
FOVx = (M - 1) * Δx #[m]
FOVy = (N - 1) * Δy #[m]
x = (-FOVx / 2):Δx:(FOVx / 2) #spin coordinates
y = (-FOVy / 2):Δy:(FOVy / 2) #spin coordinates
x, y = x .+ y' * 0, x * 0 .+ y' #grid points

# Define spin property vectors
ρ_outer = 1287.4 * 1e-3;
ρ_inner = 1306.5 * 1e-3;
T1_outer = 726.09 * 1e-3;
T1_inner = 1283.43 * 1e-3;
T2_outer = 242.08 * 1e-3;
T2_inner = 423.05 * 1e-3;
T2s_outer = 113.57 * 1e-3;
T2s_inner = 175.26 * 1e-3;

Δw_outer = 0;
Δw_inner = 0;
ρ = (reshape(Float64.(slice.==2), size(slice)[1], size(slice)[2]))*ρ_outer +
    (reshape(Float64.(slice.==3), size(slice)[1], size(slice)[2]))*ρ_inner;
T1 = (reshape(Float64.(slice.==2), size(slice)[1], size(slice)[2]))*T1_outer +
     (reshape(Float64.(slice.==3), size(slice)[1], size(slice)[2]))*T1_inner;
T2 = (reshape(Float64.(slice.==2), size(slice)[1], size(slice)[2]))*T2_outer +
     (reshape(Float64.(slice.==3), size(slice)[1], size(slice)[2]))*T2_inner;
T2s = (reshape(Float64.(slice.==2), size(slice)[1], size(slice)[2]))*T2s_outer +
      (reshape(Float64.(slice.==3), size(slice)[1], size(slice)[2]))*T2s_inner;
Δw = (reshape(Float64.(slice.==2), size(slice)[1], size(slice)[2]))*Δw_outer +
     (reshape(Float64.(slice.==3), size(slice)[1], size(slice)[2]))*Δw_inner;

# Define the phantom
phantom_obj = Phantom{Float64}(
    name = "cylindrical_phantom",
	x = x[ρ.!=0],
	y = y[ρ.!=0],
	z = 0*x[ρ.!=0],
	ρ = ρ[ρ.!=0],
	T1 = T1[ρ.!=0],
	T2 = T2[ρ.!=0],
	T2s = T2s[ρ.!=0],
	Δw = Δw[ρ.!=0],
);
@info "Preparing phantoms... done."
# Plot phantom map
# plot_phantom_map(obj, :T1)

# Load sequence
@info "Loading sequences..."
filename = seqFolder*radical*".seq" 
seq = read_seq(filename); # Pulseq file
sequencePlot = plot_seq(seq)
savefig(sequencePlot,"Results/Sequences/sequence_"*radical*".html")
@info "Loading sequences... done."

# Plot readout trajectory
@info "Writing readout trajectory..."
kspace = plot_kspace(seq) # plot trajectory
savefig(kspace,"Results/Trajectories/kspace_"*radical*".html")
@info "Writing readout trajectory... done."

# Simulate sequence
@info "Simulating sequence..."
if pantom_choice == "brain"
    obj = brain_phantom2D() # to use brain phantom
else
    obj = phantom_obj # to use phantom
end
sim_params = KomaMRICore.default_sim_params();
sys = Scanner();
sys.B0 = 3.0; # T
obj.z .= 0;
raw = simulate(obj, seq, sys; sim_params);
@info "Simulating sequence... done."

# Reconstruct image
@info "Reconstructing image..."
function reconstruct_2d_image(raw::RawAcquisitionData)
    acqData = AcquisitionData(raw)
    acqData.traj[1].circular = false #Removing circular window
    C = maximum(2*abs.(acqData.traj[1].nodes[:]))  #Normalize k-space to -.5 to .5 for NUFFT
    acqData.traj[1].nodes = acqData.traj[1].nodes[1:2,:] ./ C
    Nx, Ny = raw.params["reconSize"][1:2]
    recParams = Dict{Symbol,Any}()
    recParams[:reconSize] = (Nx, Ny)
    recParams[:densityWeighting] = true
    rec = reconstruction(acqData, recParams)
    image3d  = reshape(rec.data, Nx, Ny, :)
    image2d = (abs.(image3d) * prod(size(image3d)[1:2]))[:,:,1]
    return image2d
end

# Plot result
# plot_image(image)

image = reconstruct_2d_image(raw);
img = plot_image(image)
savefig(img,"Results/Images/image_"*radical*".html")
@info "Reconstructing image... done."
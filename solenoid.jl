### A Pluto.jl notebook ###
# v0.12.16

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ b49dd7c8-3772-11eb-3414-bb1f9e84b748
begin
	using LaTeXStrings
	using Plots
	using PlutoUI
	using LinearAlgebra
	using Test
end

# ╔═╡ 7abc4f04-3772-11eb-1c9b-712985ec2af7
md"""
### Dependencies
"""

# ╔═╡ f8e62384-3772-11eb-23fb-41462d88e988
function solenoid(x, s)
	
	s₀, s₁ = s[1], s[2]
	
	r = sqrt(x[1]*x[1] + x[2]*x[2])
	θ = (atan(x[2],x[1]) + 2π) % (2π) 
	z = x[3]
	
	r₁ = s₀ + (r - s₀)/s₁ + cos(θ)/2
	θ₁ = 2θ
	z₁ = z/s₁ + sin(θ)/2
	
	xn = similar(x)
	xn[1] = r₁*cos(θ₁)
	xn[2] = r₁*sin(θ₁)
	xn[3] = z₁
	
	return xn
end

# ╔═╡ 1f1702b4-3b22-11eb-2013-d7d91678263e
function random_solenoid(x, s, p=0.5)
	
	s₀, s₁ = s[1], s[2]
	#s₀ = 2s₀
	if rand() < p 
		s₀ = 2s₀
	end
	r = sqrt(x[1]*x[1] + x[2]*x[2])
	θ = (atan(x[2],x[1]) + 2π) % (2π) 
	z = x[3]
	
	r₁ = s₀ + (r - s₀)/s₁ + cos(θ)/2
	θ₁ = 2θ
	z₁ = z/s₁ + sin(θ)/2
	
	xn = similar(x)
	xn[1] = r₁*cos(θ₁)
	xn[2] = r₁*sin(θ₁)
	xn[3] = z₁
	
	return xn
end

# ╔═╡ 9d23a890-3773-11eb-1d5e-295158261eea
function run(method, x₀, s, n_steps)
	n = 1
	orbit = zeros(3, n_steps)
	x₁ = copy(x₀)
	while n <= n_steps
		x₁ = method(x₁, s)
		orbit[:,n] = x₁
		n += 1
	end
	return orbit
end

# ╔═╡ 5777b732-3b2e-11eb-2fe8-35b50f9c6651
function run(method, x₀, s, n_steps, p)
	n = 1
	orbit = zeros(3, n_steps)
	x₁ = copy(x₀)
	while n <= n_steps
		x₁ = method(x₁, s, p)
		orbit[:,n] = x₁
		n += 1
	end
	return orbit
end

# ╔═╡ 86f96d6c-39b6-11eb-3e44-e3a3d68a6957
function spinup(method, x₀, s, n_steps)
	n = 1
	x₁ = copy(x₀)
	while n < n_steps
		x₁ = method(x₁, s)
		n += 1
	end
	return x₁
end

# ╔═╡ afd50d1c-3776-11eb-2696-abce7d038b88
begin
	x₀ = rand(3)
	n_steps = 5000
	s = [1.0, 4.0]
	x₀ = spinup(random_solenoid, x₀, s, 1000)
	orbit = run(random_solenoid, x₀, s, n_steps)
end

# ╔═╡ 3a605d5e-3776-11eb-34ff-67296e7637f3
let 
	plt = plot3d(
    1,
    xlim = (-3, 3),
    ylim = (-4, 3),
    zlim = (-0.7, 0.7),
    title = "Solenoid Attractor",
    marker = 2,
	leg = false,
	linealpha = 0,
	xlabel = "x",
	ylabel = "y",
	zlabel = "z"
)
@gif for n = 1:n_steps
	push!(plt, orbit[1,n], orbit[2,n], orbit[3,n])
	end every 10
end

# ╔═╡ a4a93482-39b1-11eb-0753-c5aeb0eda8ae
let
	
	p1 = plot(orbit[1,:], orbit[2,:], m=:o, ms=2, linealpha=0, leg=false, xlabel="x", ylabel="y")
	p2 = plot(orbit[2,:], orbit[3,:], m=:o, ms=2, linealpha=0, leg=false, xlabel="y", ylabel="z")

	plot(p1, p2, layout = grid(1, 2, widths=[0.5, 0.5]))
end


# ╔═╡ 5720aa0c-38ed-11eb-073e-2d5e0332329d
md"""
### Lyapunov exponents
"""

# ╔═╡ c619c9e4-390a-11eb-3819-3d17ff4aecd2
function tangent(x, v, s=[1.,4.])
		r_sq = x[1]*x[1] + x[2]*x[2]
		r = sqrt(r_sq)
		θ = (atan(x[2], x[1]) + 2π) % (2π) 
		z = x[3]
		
		ct, st = cos(θ), sin(θ)
		
		r₁ = s[1] + (r - s[1])/s[2] + ct/2
		θ₁ = 2θ
		z₁ = z/s[2] + st/2
		
		ct1, st1 = cos(θ₁), sin(θ₁)
		
		dx1_dr1 = ct1
		dx1_dθ1 = -r₁*st1
		dy1_dr1 = st1
		dy1_dθ1 = r₁*ct1
		
		dr1_dr = 1/s[2]
		dr1_dθ = -st/2
		dθ1_dθ = 2
		dz1_dz = 1/s[2]
		dz1_dθ = ct/2
		
		
		dr_dx = x[1]/r
		dr_dy = x[2]/r
		dθ_dx = -x[2]/r_sq
		dθ_dy = x[1]/r_sq
		
		dx1_dr = dx1_dr1*dr1_dr 
		dx1_dθ = dx1_dr1*dr1_dθ + dx1_dθ1*dθ1_dθ
		dy1_dr = dy1_dr1*dr1_dr 
		dy1_dθ = dy1_dr1*dr1_dθ + dy1_dθ1*dθ1_dθ
		
		
		v₁ = similar(v)
		v₁[1] = dx1_dr*dr_dx*v[1] + 
			   dx1_dθ*dθ_dx*v[1] + 
			   dx1_dr*dr_dy*v[2] + 
			   dx1_dθ*dθ_dy*v[2] 
			   
			   
		v₁[2] = dy1_dr*dr_dx*v[1] + 
			   dy1_dθ*dθ_dx*v[1] + 
			   dy1_dr*dr_dy*v[2] + 
			   dy1_dθ*dθ_dy*v[2] 
		
		v₁[3] = dz1_dθ*dθ_dx*v[1] +
			   dz1_dθ*dθ_dy*v[2] +
			   dz1_dz*v[3]
		return v₁
end

# ╔═╡ ca2dbc4e-3972-11eb-15e0-c595f6d2d087
function test_tangent(x, v, s=[1.,4.],ϵ=1.e-6)
	fx = solenoid(x, s)
	df_dx = solenoid(x .+ ϵ*[1., 0., 0.], s) - solenoid(x .- ϵ*[1., 0., 0.], s)
	df_dy = solenoid(x .+ ϵ*[0., 1., 0.], s) - solenoid(x .- ϵ*[0., 1., 0.], s)
	df_dz = solenoid(x .+ ϵ*[0., 0., 1.], s) - solenoid(x .- ϵ*[0., 0., 1.], s)
	v_ana = tangent(x, v)
	v_fd = Matrix([df_dx df_dy df_dz])*v/(2*ϵ)
	@show v_ana, v_fd
	@test v_ana ≈ v_fd atol=1.e-6
end

# ╔═╡ 7395d3e2-38ed-11eb-37e9-d734cb6fffae
function first_LE(x₀, s, n_steps)
	v = rand(3)
	x = copy(x₀)
	λ = 0.
	for n = 1:n_steps
		v .= tangent(x, v, s)
		α = norm(v)
		λ += log(α)/n_steps
		v ./= α
		x .= solenoid(x, s)
	end
	return λ
end

# ╔═╡ 83546b9c-39c2-11eb-0772-ff2a7d6ed0fe
function all_LEs(x₀, s, n_steps)
	v₁ = rand(3)
	v₂ = zeros(3)
	v₃ = zeros(3)
	Q = Matrix([v₁ v₂ v₃])
	R = similar(Q)
	x = copy(x₀)
	λ = zeros(3)
	n_spinup = 100
	α = 0.
	for n = 1:n_steps + n_spinup
		Q .= Matrix([v₁ v₂ v₃])
		A = qr(Q)
		Q .= Array(A.Q)
		R .= A.R
		@show R[1,1], norm(v₁)
		if n > n_spinup
			λ .+= log.(abs.(diag(R)))/n_steps
			α += log(norm(v₁))/n_steps
		end	
		
		v₁ .= Q[:,1]
		v₂ .= Q[:,2]
		v₃ .= Q[:,3]
		
		
		v₁ .= tangent(x, v₁, s)
		v₂ .= tangent(x, v₂, s)
		v₃ .= tangent(x, v₃, s)
		x .= solenoid(x, s)
	end
	@show α
	return λ
end

# ╔═╡ fcbb4b38-3b25-11eb-3557-8979ae004fb0
function all_random_LEs(x₀, s, n_steps,p=0.5)
	v₁ = rand(3)
	v₂ = zeros(3)
	v₃ = zeros(3)
	Q = Matrix([v₁ v₂ v₃])
	R = similar(Q)
	x = copy(x₀)
	λ = zeros(3)
	n_spinup = 100
	α = 0.
	s₀, s₁ = s
	for n = 1:n_steps + n_spinup
		Q .= Matrix([v₁ v₂ v₃])
		A = qr(Q)
		Q .= Array(A.Q)
		R .= A.R
		if n > n_spinup
			λ .+= log.(abs.(diag(R)))/n_steps
			α += log(norm(v₁))/n_steps
		end	
		
		v₁ .= Q[:,1]
		v₂ .= Q[:,2]
		v₃ .= Q[:,3]
		
		
		v₁ .= tangent(x, v₁, [s₀, s₁])
		v₂ .= tangent(x, v₂, [s₀, s₁])
		v₃ .= tangent(x, v₃, [s₀, s₁])
		s₀ = s[1]
		if rand() < p
			s₀ = 2s₀
		end
		x .= solenoid(x, [s₀, s₁])
	end
	@show α
	return λ
end

# ╔═╡ bbe580e0-3972-11eb-0fc7-4d95edb00ca0
test_tangent(rand(3), rand(3))

# ╔═╡ 204d842c-39ca-11eb-19fe-9fdffed8d7df
function compute_LEs(s) 
	n_le = 100
	x = spinup(solenoid, rand(3), s, n_le)
	return all_LEs(x, s, 1000)
end

# ╔═╡ e5328cfe-3b25-11eb-29ca-b376069a083a
function compute_random_LEs(s,p=0.5) 
	n_le = 100
	x = spinup(solenoid, rand(3), s, n_le)
	return all_random_LEs(x, s, 3000, p)
end

# ╔═╡ 1a147aa8-3a5a-11eb-2717-47f73da03c14
n_p = 10

# ╔═╡ 10c7b4e2-3a5f-11eb-1505-df9942ddc7d5
md""" 
### First parameter variation
"""

# ╔═╡ 25ab64f0-3a53-11eb-260d-2d71467086fe
begin
	les_1 = zeros(3, n_p)
	s1 = LinRange(1.0, 6.5, n_p)
	for i = 1:n_p
		les_1[:,i] = compute_LEs([s1[i], 4.0])
	end
	les_1 = les_1'
	p1 = plot(s1, les_1[:,1], m=:o, title="1st LE", leg=false)
	p2 = plot(s1, les_1[:,2], m=:o, xlim=(1.0, 2.6), ylim=(-2, -1), title="2nd LE", leg=false)
	p3 = plot(s1, les_1[:,3], m=:o, xlim=(1.0, 2.6), ylim=(-2, -1), title="3rd LE", leg=false)
	
	plot(p1, p2, p3, layout = grid(1, 3, widths=[0.3, 0.3, 0.3]))
end



# ╔═╡ d2ec20b8-3b26-11eb-0f23-9d84da28194c
begin
	les_r1 = zeros(3, n_p)
	for i = 1:n_p
		les_r1[:,i] = compute_random_LEs([s1[i], 4.0],0.9)
	end
	les_r1 = les_r1'
	p14 = plot(s1, les_r1[:,1], m=:o, title="1st LE", leg=false)
	p15 = plot(s1, les_r1[:,2], m=:o, title="2nd LE", leg=false)
	p16 = plot(s1, les_r1[:,3], m=:o, title="3rd LE", leg=false)
	
	plot(p14, p15, p16, layout = grid(1, 3, widths=[0.3, 0.3, 0.3]))
end



# ╔═╡ 24c6af0c-3a5f-11eb-0fd7-135217ab59c5
md""" 
### Second parameter variation
"""

# ╔═╡ 1c2fb750-3a5d-11eb-347c-49a673d2c39b
begin
	s2 = LinRange(2.0, 10., n_p)
	les_2 = zeros(n_p, 3)
	for i = 1:n_p
		les_2[i,:] = compute_LEs([1.0, s2[i]])
	end
	
	p4 = plot(s2, les_2[:,1], m=:o,title="1st LE", leg=false)
	p5 = plot(s2, les_2[:,2], m=:o, title="2nd LE", leg=false)
	p6 = plot(s2, les_2[:,3], m=:o, title="3rd LE", leg=false)
	
	plot(p4, p5, p6, layout = grid(1, 3, widths=[0.3, 0.3, 0.3]))
end

# ╔═╡ 96387e4c-3b2a-11eb-0d3a-cdc94eaa8f9f
begin
	
	les_r2 = zeros(n_p, 3)
	for i = 1:n_p
		les_r2[i,:] = compute_random_LEs([1.0, s2[i]])
	end
	
	p17 = plot(s2, les_r2[:,1], m=:o,title="1st LE", leg=false)
	p18 = plot(s2, les_r2[:,2], m=:o, title="2nd LE", leg=false)
	p19 = plot(s2, les_r2[:,3], m=:o, title="3rd LE", leg=false)
	
	plot(p17, p18, p19, layout = grid(1, 3, widths=[0.3, 0.3, 0.3]))
end

# ╔═╡ 9ac38e86-3a60-11eb-2c7c-7b7e43324ac4
@bind n Slider(1:n_p, show_value=true)

# ╔═╡ ca656df8-3a60-11eb-1e9c-d1f1b6b68a6c
begin
	p7 = plot(s2[1:n], les_2[1:n,1], m=:o, ylim=(minimum(les_2[:,1]), maximum(les_2[:,1])), xlim=(minimum(s2), maximum(s2)), title="1st LE", leg=false)
end

# ╔═╡ 7fc92bb0-3a63-11eb-0eac-5faeeefce124
begin
	x₀ .= spinup(solenoid, x₀, [1.0, s2[n]], 500)
	orbit_s2 = zeros(n_steps, 3, n_p)
	orbit_s2[:,:,n] = run(solenoid, x₀, [1.0, s2[n]], n_steps)'
	p8 = plot(orbit_s2[:,1,n], orbit_s2[:,2,n], m=:o, ms=2, linealpha=0, leg=false, xlabel="x", ylabel="y")
	p9 = plot(orbit_s2[:,2,n], orbit_s2[:,3,n], m=:o, ms=2, linealpha=0, leg=false, xlabel="y", ylabel="z")

	plot(p8, p9, layout = grid(1, 2, widths=[0.5, 0.5]))
end

# ╔═╡ 6e529432-3a65-11eb-2226-15734d6aa29b
@bind m Slider(1:n_p, show_value=true)

# ╔═╡ 6c52e1aa-3a65-11eb-3ebf-6d24b999a3d0
begin
	p10 = plot(s1[1:m], les_1[1:m,1], m=:o, xlim=(minimum(s1), maximum(s1)), ylim=(minimum(les_1[:,1]), maximum(les_1[:,1])),title="1st LE", xlabel=L"s_1", ylabel=L"\lambda_1", leg=false)
end

# ╔═╡ 09203cd4-3a67-11eb-3b2a-fd959253ea1f
begin
	x₀ .= spinup(solenoid, x₀, [s1[m], 4.0], 5000)
	orbit_s1 = zeros(n_steps, 3, n_p)
	orbit_s1[:,:,m] = run(solenoid, x₀, [s1[m], 4.0], n_steps)'
	p11 = plot(orbit_s1[:,1,m], orbit_s1[:,2,m], m=:o, ms=2, linealpha=0, xlim=(-7.5,7.5), ylim=(-7.5,7.5),leg=false, xlabel="x", ylabel="y")
	p12 = plot(orbit_s1[:,2,m], orbit_s1[:,3,m], m=:o, ms=2, linealpha=0,
		xlim=(-7.5,7.5), ylim=(-1.,1.),leg=false, xlabel="y", ylabel="z")

	plot(p11, p12, layout = grid(1, 2, widths=[0.5, 0.5]))
end

# ╔═╡ 9268f956-3a6a-11eb-258b-abeddba30664
md""" 
### Frobenius-Perron Operator
"""


# ╔═╡ 0fbdd468-3b37-11eb-071a-392c849e79d1
md"""
The Frobenius-Perron operator $P:L^1\to L^1$ evolves probability densities under $\varphi$. For any set $A$, and a bounded function $g$,
 $\int_A g\; P f \; dx = \int_{\varphi^{-1} A} f\; (g\circ\varphi)\; dx.$
This operator lets us analyze ensemble behavior.
"""

# ╔═╡ fecf7c70-3b3a-11eb-1617-17a2f958a00c
md"""
In hyperbolic systems, $P$ may not be compact. But, we nevertheless try to approximate this operator on a finite-dimensional indicator function basis.
One way to obtain a finite-dimensional 

"""

# ╔═╡ d6727a82-3a6a-11eb-0fa9-7f131ee65966
function construct_transition_matrix(orbit, n_nodes)
	P = zeros(n_nodes^3, n_nodes^3)
	n = size(orbit)[2]
	eps = 0.01
	x_min, x_max = minimum(orbit[1,:]) - eps, maximum(orbit[1,:]) + eps
	y_min, y_max = minimum(orbit[2,:]) - eps, maximum(orbit[2,:]) + eps
	z_min, z_max = minimum(orbit[3,:]) - eps, maximum(orbit[3,:]) + eps
	dx = (x_max - x_min)/n_nodes
	dy = (y_max - y_min)/n_nodes
	dz = (z_max - z_min)/n_nodes
	
	
	x, y, z = orbit[:,1]
	pre_ind_x = ceil(Int64,(x - x_min)/dx)
	pre_ind_y = ceil(Int64,(y - y_min)/dy)
	pre_ind_z = ceil(Int64,(z - z_min)/dz)
	pre_ind = pre_ind_x + (pre_ind_y-1)*n_nodes + (pre_ind_z-1)*n_nodes*n_nodes
	
	for i = 2:n
		
		x, y, z = orbit[:,i]
		
		ind_x = ceil(Int64,(x - x_min)/dx)
		ind_y = ceil(Int64,(y - y_min)/dy)
		ind_z = ceil(Int64,(z - z_min)/dz)
		
		ind = ind_x + (ind_y-1)*n_nodes + (ind_z-1)*n_nodes*n_nodes
		
		
		P[ind, pre_ind] += 1
		pre_ind = ind
	end
	for i = 1:n_nodes^3
		a = sum(P[:,i])
		if a > 0
			P[:, i] ./= sum(P[:,i]) 
		end
	end
	return P'
end

# ╔═╡ 78d0a378-3a76-11eb-038f-5b319336a827
begin
	n_nodes = 5
	P1 = zeros(n_nodes^3, n_nodes^3, n_p)
	for (i, s1i) in enumerate(s1)
		@show s1i
		x = spinup(solenoid, rand(3), [s1i, 4.0], 1000)
		test_orbit = run(solenoid, x, [s1i, 4.0], 1000000)
		P1[:,:,i]  = construct_transition_matrix(test_orbit, n_nodes)
	end
end

# ╔═╡ 9caf2aa8-3b2c-11eb-3d20-11289e17689f
begin
	
	P1_r = zeros(n_nodes^3, n_nodes^3, n_p)
	for (i, s1i) in enumerate(s1)
		@show s1i
		x = spinup(solenoid, rand(3), [s1i, 4.0], 1000)
		test_orbit = run(random_solenoid, x, [s1i, 4.0], 2000000)
		P1_r[:,:,i]  = construct_transition_matrix(test_orbit, n_nodes)
	end
end

# ╔═╡ 4144af3c-3b07-11eb-028c-6ddd7b0c000d
begin
	rpr1 = 1im*zeros(n_nodes^3, n_p)
	for i =1:n_p
		rpr1[:,i] = eigvals(P1[:,:,i])
	end
end

# ╔═╡ db1230b0-3b2c-11eb-2c97-c31cd04d89b1
begin
	rpr1_r = 1im*zeros(n_nodes^3, n_p)
	for i =1:n_p
		rpr1_r[:,i] = eigvals(P1_r[:,:,i])
	end
end

# ╔═╡ 84a7b078-3b0f-11eb-1b67-5f903684d8a8
@bind j Slider(1:n_p, show_value=true)

# ╔═╡ 57453d90-3b06-11eb-1834-19f0f3481337
begin
	p13 = plot(real(rpr1[:,j]), imag(rpr1[:,j]), xlim=(-1,1), ylim=(-1,1), linealpha=0, ms=2, m=:o, leg=false, aspect_ratio=1, title="Eigenvalues of Frobenius-Perron operator")
	t_arr = 0.:pi/20:2π
	plot!(p13, cos.(t_arr), sin.(t_arr))
end

# ╔═╡ 9d2331a2-3b07-11eb-3f5f-0bdf673ff93d
begin
	p20 = plot(real(rpr1_r[:,j]), imag(rpr1_r[:,j]), xlim=(-1,1), ylim=(-1,1), linealpha=0, ms=2, m=:o, leg=false, aspect_ratio=1, title="Eigenvalues of Frobenius-Perron operator")
	plot!(p20, cos.(t_arr), sin.(t_arr))
end

# ╔═╡ 3d95608e-3b2f-11eb-2960-f11e81d48a29
begin
	P1_r_p = zeros(n_nodes^3, n_nodes^3, n_p)
	prob_arr = 0.:0.2:1
	n_prob = length(prob_arr)
	for (i, p_i) in enumerate(prob_arr)
		
		x = spinup(solenoid, rand(3), [2.0, 4.0], 1000)
		test_orbit = run(random_solenoid, x, [2.0, 4.0], 2000000, p_i)
		P1_r_p[:,:,i]  = construct_transition_matrix(test_orbit, n_nodes)
	end
end

# ╔═╡ e2dfc004-3b32-11eb-3c1f-d927eec4318e
begin
	rpr1_r_p = 1im*zeros(n_nodes^3, n_p)
	for i =1:n_prob
		rpr1_r_p[:,i] = eigvals(P1_r_p[:,:,i])
	end
end

# ╔═╡ 88fc686c-3b32-11eb-03ac-31d9d41b1230
@bind k Slider(1:n_prob, show_value=true)

# ╔═╡ 44c0692c-3b33-11eb-1776-c1fa4d07ed14
begin
	p21 = plot(real(rpr1_r_p[:,k]), imag(rpr1_r_p[:,k]), xlim=(-1,1.1), ylim=(-1,1), linealpha=0, ms=2, m=:o, leg=false, aspect_ratio=1)
	plot!(p21, cos.(t_arr), sin.(t_arr))
	rpr_slow = rpr1_r_p[abs.(rpr1_r_p[:,k]) .> 0.4,k]
	plot!(p21, real.(rpr_slow), imag.(rpr_slow), m=:p, ms=4, linealpha=0,color=:red)
end

# ╔═╡ Cell order:
# ╟─7abc4f04-3772-11eb-1c9b-712985ec2af7
# ╠═b49dd7c8-3772-11eb-3414-bb1f9e84b748
# ╠═f8e62384-3772-11eb-23fb-41462d88e988
# ╠═1f1702b4-3b22-11eb-2013-d7d91678263e
# ╠═9d23a890-3773-11eb-1d5e-295158261eea
# ╠═5777b732-3b2e-11eb-2fe8-35b50f9c6651
# ╠═86f96d6c-39b6-11eb-3e44-e3a3d68a6957
# ╠═afd50d1c-3776-11eb-2696-abce7d038b88
# ╠═3a605d5e-3776-11eb-34ff-67296e7637f3
# ╠═a4a93482-39b1-11eb-0753-c5aeb0eda8ae
# ╠═5720aa0c-38ed-11eb-073e-2d5e0332329d
# ╠═c619c9e4-390a-11eb-3819-3d17ff4aecd2
# ╟─ca2dbc4e-3972-11eb-15e0-c595f6d2d087
# ╟─7395d3e2-38ed-11eb-37e9-d734cb6fffae
# ╠═83546b9c-39c2-11eb-0772-ff2a7d6ed0fe
# ╠═fcbb4b38-3b25-11eb-3557-8979ae004fb0
# ╠═bbe580e0-3972-11eb-0fc7-4d95edb00ca0
# ╠═204d842c-39ca-11eb-19fe-9fdffed8d7df
# ╠═e5328cfe-3b25-11eb-29ca-b376069a083a
# ╠═1a147aa8-3a5a-11eb-2717-47f73da03c14
# ╠═10c7b4e2-3a5f-11eb-1505-df9942ddc7d5
# ╠═25ab64f0-3a53-11eb-260d-2d71467086fe
# ╠═d2ec20b8-3b26-11eb-0f23-9d84da28194c
# ╠═24c6af0c-3a5f-11eb-0fd7-135217ab59c5
# ╠═1c2fb750-3a5d-11eb-347c-49a673d2c39b
# ╠═96387e4c-3b2a-11eb-0d3a-cdc94eaa8f9f
# ╠═9ac38e86-3a60-11eb-2c7c-7b7e43324ac4
# ╠═ca656df8-3a60-11eb-1e9c-d1f1b6b68a6c
# ╠═7fc92bb0-3a63-11eb-0eac-5faeeefce124
# ╠═6e529432-3a65-11eb-2226-15734d6aa29b
# ╠═6c52e1aa-3a65-11eb-3ebf-6d24b999a3d0
# ╠═09203cd4-3a67-11eb-3b2a-fd959253ea1f
# ╠═9268f956-3a6a-11eb-258b-abeddba30664
# ╠═0fbdd468-3b37-11eb-071a-392c849e79d1
# ╠═fecf7c70-3b3a-11eb-1617-17a2f958a00c
# ╠═d6727a82-3a6a-11eb-0fa9-7f131ee65966
# ╠═78d0a378-3a76-11eb-038f-5b319336a827
# ╠═9caf2aa8-3b2c-11eb-3d20-11289e17689f
# ╠═4144af3c-3b07-11eb-028c-6ddd7b0c000d
# ╠═db1230b0-3b2c-11eb-2c97-c31cd04d89b1
# ╠═84a7b078-3b0f-11eb-1b67-5f903684d8a8
# ╠═57453d90-3b06-11eb-1834-19f0f3481337
# ╠═9d2331a2-3b07-11eb-3f5f-0bdf673ff93d
# ╠═3d95608e-3b2f-11eb-2960-f11e81d48a29
# ╠═e2dfc004-3b32-11eb-3c1f-d927eec4318e
# ╠═88fc686c-3b32-11eb-03ac-31d9d41b1230
# ╠═44c0692c-3b33-11eb-1776-c1fa4d07ed14

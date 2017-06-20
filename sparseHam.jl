# sparseHam.jl
# sparse representatin of J-K Hamiltonian
# Alan Morningstar
# May 2017


# container for Hamiltonian couplings
immutable couplings
    # 1st nearest neighbor
    J1::Float64;
    # plaquette terms
    K::Float64;
end;


# function for building the sparse Hamiltonian
function constructSparseHam(basis::SzkxkyBasis,c::couplings,s::sector,l::lattice)

    # lattice
    Lx::Int64 = l.Lx;
    Ly::Int64 = l.Ly;
    N::Int64 = l.N;
    # couplings
    J1::Float64 = c.J1;
    K::Float64 = c.K;
    # momentum
    kx::Float64 = s.kx;
    ky::Float64 = s.ky;

    # non-zero couplings
    J1nz::Bool = (J1 != 0.0);
    Knz::Bool = (K != 0.0);

    # store location and value of non-zero matrix elements in CSC format
    Jpointers::Array{Int32,1} = Array{Int32,1}(basis.dim+1);
    I::Array{Int32,1} = Int32[];
    M::Array{Complex128,1} = Complex128[];

    # allocate memory once before the loops
    # -------------------------------------
    b::UInt64 = 0;
    sb::Array{UInt64,1} = Array{UInt64,1}(l.N);
    nb::Float64 = 0.0;
    Hbb::Complex128 = 0.0+0.0im;
    p::Array{Int64,1} = Array{UInt64,1}(length(l.nbrs[1]));
    sp::Array{UInt64,1} = Array{UInt64,1}(length(p));
    sPw12::Int64 = sPw34::Int64 = sPw13::Int64 = sPw24::Int64 = sPw14::Int64 = sPw23::Int64 = sPw1234::Int64 = sPw1D2D::Int64 = sPw1L3L::Int64 = 0;
    c12::Bool = c13::Bool = c14::Bool = c23::Bool = c1234::Bool = true;
    a::UInt64 = UInt64(0);
    aRep::UInt64 = UInt64(0);
    lx::Int64 = ly::Int64 = 0;
    aRepIndex::Int32 = Int32(0);
    Hsite::Complex128 = 0.0+0.0im;
    # -------------------------------------

    # loop over basis
    for bIndex::Int64 in 1:basis.dim
        # CSC formatting
        Jpointers[bIndex] = Int32(length(I)+1);

        # spin states of basis
        b = basis.b[bIndex]; # integer rep.
        for bit in 1:l.N
            sb[bit] = readBit(b,bit); # spin array rep.
        end;
        # normalization constant
        nb = basis.n[bIndex];

        # initialize the diagonal matrix element
        Hbb = 0.0 + 0.0im;

        # loop over lattice sites
        for site::Int64 in 1:N

            # spins at nearby sites p1,p2,p3,p4,p1D,p2D,p1L,p3L
            p = l.nbrs[site];
            sp = sb[p];
            # some common factors in the matrix elements
            sPw12 = simplePower(sp[1] + sp[2]);
            sPw34 = simplePower(sp[3] + sp[4]);
            sPw13 = simplePower(sp[1] + sp[3]);
            sPw24 = simplePower(sp[2] + sp[4]);
            sPw14 = simplePower(sp[1] + sp[4]);
            sPw23 = simplePower(sp[2] + sp[3]);
            sPw1234 = simplePower(sp[1] + sp[2] + sp[3] + sp[4]);
            sPw1D2D = simplePower(sp[5] + sp[6]);
            sPw1L3L = simplePower(sp[7] + sp[8]);

            # some conditions
            c12 = (sPw12 == -1);
            c13 = (sPw13 == -1);
            c14 = (sPw14 == -1 && Knz);
            c23 = (sPw23 == -1 && Knz);
            c1234 = (sp[1] + sp[2] + sp[3] + sp[4] == 2 && Knz);


            # contribute to the diagonal matrix element
            # -----------------------------------------

            Hbb += 0.25*J1*( sPw12 + sPw13 ) + 0.125*K*sPw1234;

            # compute off diagonal matrix elements
            # ------------------------------------

            # the 12 term
            if c12
                # the bra
                a = XiXj(b,p[1],p[2]);
                # the rep and transaltion of the bra
                aRep,lx,ly = representative(a,l);
                # search for this rep in the basis
                aRepIndex = basisIndex(aRep,basis);
                if aRepIndex != 0
                    # the matrix element
                    Hsite = (0.5*J1+0.125*K*(sPw34-sPw1234+2*sPw1D2D))*exp(-1.0im*(kx*lx+ky*ly))*sqrt(basis.n[aRepIndex]/nb);

                    push!(I,aRepIndex);
                    push!(M,Hsite);
                end;
            end;

            # the 13 term
            if c13
                # the bra
                a = XiXj(b,p[1],p[3]);
                # the rep and transaltion of the bra
                aRep,lx,ly = representative(a,l);
                # search for this rep in the basis
                aRepIndex = basisIndex(aRep,basis);
                if aRepIndex != 0
                    # the matrix element
                    Hsite = (0.5*J1+0.125*K*(sPw24-sPw1234+2*sPw1L3L))*exp(-1.0im*(kx*lx+ky*ly))*sqrt(basis.n[aRepIndex]/nb);

                    push!(I,aRepIndex);
                    push!(M,Hsite);
                end;
            end;

            # the 14 term
            if c14 && K != 0.0
                # the bra
                a = XiXj(b,p[1],p[4]);
                # the rep and transaltion of the bra
                aRep,lx,ly = representative(a,l);
                # search for this rep in the basis
                aRepIndex = basisIndex(aRep,basis);
                if aRepIndex !=0
                    # the matrix element
                    Hsite = -0.250*K*sPw23*exp(-1.0im*(kx*lx+ky*ly))*sqrt(basis.n[aRepIndex]/nb);

                    push!(I,aRepIndex);
                    push!(M,Hsite);
                end;
            end;

            # the 23 term
            if c23 && K != 0.0
                # the bra
                a = XiXj(b,p[2],p[3]);
                # the rep and transaltion of the bra
                aRep,lx,ly = representative(a,l);
                # search for this rep in the basis
                aRepIndex = basisIndex(aRep,basis);
                if aRepIndex != 0
                    # the matrix element
                    Hsite23= -0.25*K*sPw14*exp(-1.0im*(kx*lx+ky*ly))*sqrt(basis.n[aRepIndex]/nb);

                    push!(I,aRepIndex);
                    push!(M,Hsite);
                end;
            end;

            # the 1234 term
            if c1234 && K != 0.0
                # the bra
                a = XiXjXkXl(b,p[1],p[2],p[3],p[4]);
                # the rep and transaltion of the bra
                aRep,lx,ly = representative(a,l);
                # search for this rep in the basis
                aRepIndex = basisIndex(aRep,basis);
                if aRepIndex != 0
                    # the matrix element
                    Hsite = 0.125*K*(2-sPw12-sPw34-sPw13-sPw24+sPw14+sPw23)*exp(-1.0im*(kx*lx+ky*ly))*sqrt(basis.n[aRepIndex]/nb);

                    push!(I,aRepIndex);
                    push!(M,Hsite);
                end;
            end;

        end;

        # push diagonal matrix element to list of matrix elements
        push!(I,bIndex);
        push!(M,Hbb);

        # CSC formatting
        sortTwo!(I[Jpointers[bIndex]:end],M[Jpointers[bIndex]:end],1,length(I[Jpointers[bIndex]:end]));


    end;

    # CSC formatting
    Jpointers[end] = Int32(length(I)+1);

    H::SparseMatrixCSC{Complex128,Int32} = SparseMatrixCSC{Complex128,Int32}(basis.dim, basis.dim, Jpointers, I, M);
    return H;
end;

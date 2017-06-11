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

    # store location and value of non-zero matrix elements
    I::Array{Int32,1} = Int32[];
    J::Array{Int32,1} = Int32[];
    M::Array{Complex128,1} = Complex128[];

    # allocate memory once before loop


    # loop over basis
    for bIndex::Int64 in 1:basis.dim

        # spin states of basis
        b::UInt64 = basis.b[bIndex]; # integer rep.
        sb::Array{UInt64,1} = [readBit(b,bit) for bit in 1:l.N]; # spin array rep.
        # normalization constant
        nb::Float64 = basis.n[bIndex];

        # initialize the diagonal matrix element
        Hbb::Complex128 = 0.0 + 0.0im;

        # loop over lattice sites
        for site::Int64 in 1:N

            # spins at nearby sites p1,p2,p3,p4,p1D,p2D,p1L,p3L
            p::Array{Int64,1} = l.nbrs[site];
            sp::Array{UInt64,1} = sb[p];
            # some common factors in the matrix elements
            sPw12::Int64 = simplePower(sp[1] + sp[2]);
            sPw34::Int64 = simplePower(sp[3] + sp[4]);
            sPw13::Int64 = simplePower(sp[1] + sp[3]);
            sPw24::Int64 = simplePower(sp[2] + sp[4]);
            sPw14::Int64 = simplePower(sp[1] + sp[4]);
            sPw23::Int64 = simplePower(sp[2] + sp[3]);
            sPw1234::Int64 = simplePower(sp[1] + sp[2] + sp[3] + sp[4]);
            sPw1D2D::Int64 = simplePower(sp[5] + sp[6]);
            sPw1L3L::Int64 = simplePower(sp[7] + sp[8]);

            # some conditions
            c12::Bool = (sPw12 == -1);
            c13::Bool = (sPw13 == -1);
            c14::Bool = (sPw14 == -1 && Knz);
            c23::Bool = (sPw23 == -1 && Knz);
            c1234::Bool = (sp[1] + sp[2] + sp[3] + sp[4] == 2 && Knz);


            # contribute to the diagonal matrix element
            # -----------------------------------------
            if J1nz
                Hbb += 0.25*J1*( sPw12 + sPw13 );
            end;
            if Knz
                Hbb += 0.125*K*sPw1234;
            end;

            # compute off diagonal matrix elements
            # ------------------------------------

            # the 12 term
            if c12
                # the bra
                a12::UInt64 = XiXj(b,p[1],p[2]);
                # the rep and transaltion of the bra
                a12rep::UInt64,lx12::Int64,ly12::Int64 = representative(a12,l);
                # search for this rep in the basis
                a12repIndex::Int32 = basisIndex(a12rep,basis);
                # the matrix element
                Hsite12::Complex128 = 0.5*J1+0.125*K*(sPw34-sPw1234+2*sPw1D2D)*exp(-1.0im*(kx*lx12+ky*ly12))*sqrt(basis.n[a12repIndex]/nb);

                push!(J,bIndex);
                push!(I,a12repIndex);
                push!(M,Hsite12);
            end;

            # the 13 term
            if c13
                # the bra
                a13::UInt64 = XiXj(b,p[1],p[3]);
                # the rep and transaltion of the bra
                a13rep::UInt64,lx13::Int64,ly13::Int64 = representative(a13,l);
                # search for this rep in the basis
                a13repIndex::Int32 = basisIndex(a13rep,basis);
                # the matrix element
                Hsite13::Complex128 = 0.5*J1*+0.125*K*(sPw24-sPw1234+2*sPw1L3L)*exp(-1.0im*(kx*lx13+ky*ly13))*sqrt(basis.n[a13repIndex]/nb);

                push!(J,bIndex);
                push!(I,a13repIndex);
                push!(M,Hsite13);
            end;

            # the 14 term
            if c14
                # the bra
                a14::UInt64 = XiXj(b,p[1],p[4]);
                # the rep and transaltion of the bra
                a14rep::UInt64,lx14::Int64,ly14::Int64 = representative(a14,l);
                # search for this rep in the basis
                a14repIndex::Int32 = basisIndex(a14rep,basis);
                # the matrix element
                Hsite14::Complex128 = -0.250*K*sPw23*exp(-1.0im*(kx*lx14+ky*ly14))*sqrt(basis.n[a14repIndex]/nb);

                push!(J,bIndex);
                push!(I,a14repIndex);
                push!(M,Hsite14);
            end;

            # the 23 term
            if c23
                # the bra
                a23::UInt64 = XiXj(b,p[2],p[3]);
                # the rep and transaltion of the bra
                a23rep::UInt64,lx23::Int64,ly23::Int64 = representative(a23,l);
                # search for this rep in the basis
                a23repIndex::Int32 = basisIndex(a23rep,basis);
                # the matrix element
                Hsite23::Complex128 = -0.25*K*sPw14*exp(-1.0im*(kx*lx23+ky*ly23))*sqrt(basis.n[a23repIndex]/nb);

                push!(J,bIndex);
                push!(I,a23repIndex);
                push!(M,Hsite23);
            end;

            # the 1234 term
            if c1234
                # the bra
                a1234::UInt64 = XiXjXkXl(b,p[1],p[2],p[3],p[4]);
                # the rep and transaltion of the bra
                a1234rep::UInt64,lx1234::Int64,ly1234::Int64 = representative(a1234,l);
                # search for this rep in the basis
                a1234repIndex::Int32 = basisIndex(a1234rep,basis);
                # the matrix element
                Hsite1234::Complex128 = 0.125*K*(2-sPw12-sPw34-sPw13-sPw24+sPw14+sPw23)*exp(-1.0im*(kx*lx1234+ky*ly1234))*sqrt(basis.n[a1234repIndex]/nb);

                push!(J,bIndex);
                push!(I,a1234repIndex);
                push!(M,Hsite1234);
            end;

        end;

        # push diagonal matrix element to list of matrix elements
        push!(J,bIndex);
        push!(I,bIndex);
        push!(M,Hbb);

    end;

    H::SparseMatrixCSC{Complex,Int32} = sparse(I,J,M,basis.dim,basis.dim);
    return H;
end;

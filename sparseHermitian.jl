# sparseHermitian.jl
# sparse Hermitian matrix type
# Alan Morningstar
# June 2017


immutable sparseHermitian{TI<:Integer,TM<:Number}

    # NOTE NOTE NOTE: diagonal elements here should have been divided by 2
    #                 and only the upper triangle of the off diagonal
    #                 elements should be given

    # number of rows in the matrix
    nRows::Int64
    # number of columns in the matrix
    nCols::Int64
    # row numbers of the first non-zero value in each column
    colPntrs::Vector{Int64}
    # row indices of non-zero elements
    rowIndcs::Vector{TI}
    # non-zero matrix element values
    nzVals::Vector{TM}

    # NOTE: optional, use for matrices with few unique matrix element values
    #       to save memory
    # non-zero matrix element pointers
    nzPntrs::Vector{TI}
    # is this a sparse pointer matrix? i.e. did you give nzPntrs?
    sparsePntrs::Bool

    # constructors

    # not a sparse matrix of pointers to matrix elements
    sparseHermitian{TI,TM}(nRows::Int64, nCols::Int64, colPntrs::Vector{Int64}, rowIndcs::Vector{TI}, nzVals::Vector{TM}) = new(nRows::Int64, nCols::Int64, colPntrs::Vector{Int64}, rowIndcs::Vector{TI}, nzVals::Vector{TM},Vector{TI}(),false)

    # a sparse matrix of pointers to matrix elements
    sparseHermitian{TI,TM}(nRows::Int64, nCols::Int64, colPntrs::Vector{Int64}, rowIndcs::Vector{TI}, nzVals::Vector{TM}, nzPntrs::Vector{TI}) = new(nRows::Int64, nCols::Int64, colPntrs::Vector{Int64}, rowIndcs::Vector{TI}, nzVals::Vector{TM}, nzPntrs::Vector{TI}, true)

end


## methods


# in place matrix * vector multiplication
function Base.A_mul_B!(y::AbstractVector,M::sparseHermitian,x::AbstractVector)

    # NOTE NOTE NOTE: this assumes the sparse Hermitian matrix has been built
    #                 properly, with diagonal matrix elements given already
    #                 divided by 2, and only the upper triangle of the
    #                 off-diagonal elements given

    # clear output vector
    y .= 0.0

    # fill output vector
    if !M.sparsePntrs

        for j::Int64 in 1:M.nCols
            for i::Int64 in M.colPntrs[j]:(M.colPntrs[j+1]-1)
                y[M.rowIndcs[i]] += x[j]*M.nzVals[i]
                y[j] += x[M.rowIndcs[i]]*conj(M.nzVals[i])
            end
        end

    else

        for j::Int64 in 1:M.nCols
            for i::Int64 in M.colPntrs[j]:(M.colPntrs[j+1]-1)
                y[M.rowIndcs[i]] += x[j]*M.nzVals[M.nzPntrs[i]]
                y[j] += x[M.rowIndcs[i]]*conj(M.nzVals[M.nzPntrs[i]])
            end
        end

    end

    return y::AbstractVector

end


# size of the matrix representation
Base.size(M::sparseHermitian) = (M.nRows, M.nCols)


# this type is a 2D matrix
Base.ndims(M::sparseHermitian) = 2


# type of matrix elements
Base.eltype(M::sparseHermitian) = eltype(M.nzVals)


# Hermitian is not, in general, symmetric
Base.issymmetric(M::sparseHermitian) = false


# this type is for Hermitian matrices
Base.ishermitian(M::sparseHermitian) = true


# number of non-zero matrix elements
Base.nnz(M::sparseHermitian) = max(length(M.nzVals),length(M.nzPntrs))


# matrix * vector multiplication
Base.:*(M::sparseHermitian,x::AbstractVector) = Base.A_mul_B!(similar(x,promote_type(Base.eltype(M),eltype(x)),size(M,1)),M,x)


# conjugate transpose matrix * vector multiplication
# NOTE: same as M*v for Hermitian matrices
Base.Ac_mul_B!(y::AbstractVector,M::sparseHermitian,x::AbstractVector) = Base.A_mul_B!(y,M,x)

module LinAlgBenchmarks

import ..BaseBenchmarks
using ..BenchmarkTrackers
using ..RandUtils

const SIZES = (16, 512)
const MATS = (Matrix, Diagonal, Bidiagonal, Tridiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
const DIVMATS = filter(x -> !(in(x, (Bidiagonal, Tridiagonal, SymTridiagonal))), MATS)

id{T}(::Type{T}) = string(T.name)
id{M<:Matrix}(::Type{M}) = "Matrix"
id{V<:Vector}(::Type{V}) = "Vector"

linalgmat(::Type{Matrix}, n) = randmat(n)
linalgmat(::Type{Diagonal}, n) = Diagonal(randvec(n))
linalgmat(::Type{Bidiagonal}, n) = Bidiagonal(randvec(n), randvec(n-1), true)
linalgmat(::Type{Tridiagonal}, n) = Tridiagonal(randvec(n-1), randvec(n), randvec(n-1))
linalgmat(::Type{SymTridiagonal}, n) = SymTridiagonal(randvec(n), randvec(n-1))
linalgmat(::Type{UpperTriangular}, n) = UpperTriangular(randmat(n))
linalgmat(::Type{LowerTriangular}, n) = LowerTriangular(randmat(n))

function linalgmat(::Type{Hermitian}, n)
    A = randmat(n)
    A = A + im*A
    return Hermitian(A + A')
end

############################
# matrix/vector arithmetic #
############################

@track BaseBenchmarks.TRACKER  "linalg arithmetic" begin
    @benchmarks begin
        [(:+, id(Vector), id(Vector), n) => +(randvec(n), randvec(n)) for n in SIZES]
        [(:-, id(Vector), id(Vector), n) => -(randvec(n), randvec(n)) for n in SIZES]
        [(:*, id(M), id(Vector), n) => *(linalgmat(M, n), randvec(n)) for n in SIZES, M in MATS]
        [(:\, id(M), id(Vector), n) => \(linalgmat(M, n), randvec(n)) for n in SIZES, M in MATS]
        [(:+, id(M), id(M), n) => +(linalgmat(M, n), linalgmat(M, n)) for n in SIZES, M in MATS]
        [(:-, id(M), id(M), n) => -(linalgmat(M, n), linalgmat(M, n)) for n in SIZES, M in MATS]
        [(:*, id(M), id(M), n) => *(linalgmat(M, n), linalgmat(M, n)) for n in SIZES, M in MATS]
        [(:/, id(M), id(M), n) => /(linalgmat(M, n), linalgmat(M, n)) for n in SIZES, M in DIVMATS]
        [(:\, id(M), id(M), n) => \(linalgmat(M, n), linalgmat(M, n)) for n in SIZES, M in DIVMATS]
    end
    @tags "array" "linalg" "arithmetic"
end

##################
# factorizations #
##################

@track BaseBenchmarks.TRACKER "factorization eig" begin
    @setup mats = (Matrix, Diagonal, Bidiagonal, SymTridiagonal, UpperTriangular, LowerTriangular)
    @benchmarks begin
        [(:eig, id(M), n) => eig(linalgmat(M, n)) for n in SIZES, M in mats]
        [(:eigfact, id(M), n) => eigfact(linalgmat(M, n)) for n in SIZES, M in mats]
    end
    @tags "array" "linalg" "factorization" "eig" "eigfact"
end

@track BaseBenchmarks.TRACKER "factorization svd" begin
    @setup mats = (Matrix, Diagonal, Bidiagonal, UpperTriangular, LowerTriangular)
    @benchmarks begin
        [(:svd, id(M), n) => svd(linalgmat(M, n)) for n in SIZES, M in mats]
        [(:svdfact, id(M), n) => svdfact(linalgmat(M, n)) for n in SIZES, M in mats]
    end
    @tags "array" "linalg" "factorization" "svd" "svdfact"
end

@track BaseBenchmarks.TRACKER "factorization lu" begin
    @setup mats = (Matrix, Tridiagonal)
    @benchmarks begin
        [(:lu, id(M), n) => lu(linalgmat(M, n)) for n in SIZES, M in mats]
        [(:lufact, id(M), n) => lufact(linalgmat(M, n)) for n in SIZES, M in mats]
    end
    @tags "array" "linalg" "factorization" "lu" "lufact"
end

@track BaseBenchmarks.TRACKER "factorization qr" begin
    @benchmarks begin
        [(:qr, id(Matrix), n) => qr(randmat(n)) for n in SIZES]
        [(:qrfact, id(Matrix), n) => qrfact(randmat(n)) for n in SIZES]
    end
    @tags "array" "linalg" "factorization" "qr" "qrfact"
end

@track BaseBenchmarks.TRACKER "factorization schur" begin
    @benchmarks begin
        [(:schur, id(Matrix), n) => schur(randmat(n)) for n in SIZES]
        [(:schurfact, id(Matrix), n) => schurfact(randmat(n)) for n in SIZES]
    end
    @tags "array" "linalg" "factorization" "schur" "schurfact"
end

@track BaseBenchmarks.TRACKER "factorization chol" begin
    @benchmarks begin
        [(:chol, id(Matrix), n) => chol(randmat(n)'*randmat(n)) for n in SIZES]
        [(:cholfact, id(Matrix), n) => cholfact(randmat(n)'*randmat(n)) for n in SIZES]
    end
    @tags "array" "linalg" "factorization" "chol" "cholfact"
end

########
# BLAS #
########

@track BaseBenchmarks.TRACKER "blas" begin
    @setup n = 1024
    @benchmarks begin
        (:dot, n) => BLAS.dot(n, randvec(n), 1, randvec(n), 1)
        (:dotu, n) => BLAS.dotu(n, randvec(Complex{Float64}, n), 1, randvec(Complex{Float64}, n), 1)
        (:dotc, n) => BLAS.dotc(n, randvec(Complex{Float64}, n), 1, randvec(Complex{Float64}, n), 1)
        (:blascopy!, n) => BLAS.blascopy!(n, randvec(n), 1, randvec(n), 1)
        (:nrm2, n) => BLAS.nrm2(n, randvec(n), 1)
        (:asum, n) => BLAS.asum(n, randvec(n), 1)
        (:axpy!, n) => BLAS.axpy!(samerand(), randvec(n), randvec(n))
        (:scal!, n) => BLAS.scal!(n, samerand(), randvec(n), 1)
        (:scal, n) => BLAS.scal(n, samerand(), randvec(n), 1)
        (:ger!, n) => BLAS.ger!(samerand(), randvec(n), randvec(n), randmat(n))
        (:syr!, n) => BLAS.syr!('U', 1.0, randvec(n), randmat(n))
        (:syrk!, n) => BLAS.syrk!('U', 'N', samerand(), randmat(n), samerand(), randmat(n))
        (:syrk, n) => BLAS.syrk('U', 'N', samerand(), randmat(n))
        (:her!, n) => BLAS.her!('U', samerand(), randvec(Complex{Float64}, n), randmat(Complex{Float64}, n))
        (:herk!, n) => BLAS.herk!('U', 'N', samerand(), randmat(Complex{Float64}, n), samerand(), randmat(Complex{Float64}, n))
        (:herk, n) => BLAS.herk('U', 'N', samerand(), randmat(Complex{Float64}, n))
        (:gbmv!, n) => BLAS.gbmv!('N', n, 1, 1, samerand(), randmat(n), randvec(n), samerand(), randvec(n))
        (:gbmv, n) => BLAS.gbmv('N', n, 1, 1, samerand(), randmat(n), randvec(n))
        (:sbmv!, n) => BLAS.sbmv!('U', n-1, samerand(), randmat(n), randvec(n), samerand(), randvec(n))
        (:sbmv, n) => BLAS.sbmv('U', n-1, samerand(), randmat(n), randvec(n))
        (:gemm!, n) => BLAS.gemm!('N', 'N', samerand(), randmat(n), randmat(n), samerand(), randmat(n))
        (:gemm, n) => BLAS.gemm('N', 'N', samerand(), randmat(n), randmat(n))
        (:gemv!, n) => BLAS.gemv!('N', samerand(), randmat(n), randvec(n), samerand(), randvec(n))
        (:gemv, n) => BLAS.gemv('N', samerand(), randmat(n), randvec(n))
        (:symm!, n) => BLAS.symm!('L', 'U', samerand(), randmat(n), randmat(n), samerand(), randmat(n))
        (:symm, n) => BLAS.symm('L', 'U', samerand(), randmat(n), randmat(n))
        (:symv!, n) => BLAS.symv!('U', samerand(), randmat(n), randvec(n), samerand(), randvec(n))
        (:symv, n) => BLAS.symv('U', samerand(), randmat(n), randvec(n))
        (:trmm!, n) => BLAS.trmm!('L', 'U', 'N', 'N', samerand(), randmat(n), randmat(n))
        (:trmm, n) => BLAS.trmm('L', 'U', 'N', 'N', samerand(), randmat(n), randmat(n))
        (:trsm!, n) => BLAS.trsm!('L', 'U', 'N', 'N', samerand(), randmat(n), randmat(n))
        (:trsm, n) => BLAS.trsm('L', 'U', 'N', 'N', samerand(), randmat(n), randmat(n))
        (:trmv!, n) => BLAS.trmv!('L', 'N', 'U', randmat(n), randvec(n))
        (:trmv, n) => BLAS.trmv('L', 'N', 'U', randmat(n), randvec(n))
        (:trsv!, n) => BLAS.trsv!('U', 'N', 'N', randmat(n), randvec(n))
        (:trsv, n) => BLAS.trsv('U', 'N', 'N', randmat(n), randvec(n))
    end
    @tags "array" "linalg" "blas"
end

end # module

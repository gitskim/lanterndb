-- functions
CREATE FUNCTION cos_dist(real[], real[]) RETURNS real
	AS 'MODULE_PATHNAME' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION hamming_dist(integer[], integer[]) RETURNS integer
	AS 'MODULE_PATHNAME' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ldb_generic_dist(real[], real[]) RETURNS real
	AS 'MODULE_PATHNAME' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ldb_generic_dist(integer[], integer[]) RETURNS real
	AS 'MODULE_PATHNAME' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- operators
DROP OPERATOR IF EXISTS <-> (real[], real[]) CASCADE;
DROP OPERATOR IF EXISTS <-> (integer[], integer[]) CASCADE;

CREATE OPERATOR <-> (
	LEFTARG = real[], RIGHTARG = real[], PROCEDURE = ldb_generic_dist,
	COMMUTATOR = '<->'
);

CREATE OPERATOR <-> (
	LEFTARG = integer[], RIGHTARG = integer[], PROCEDURE = ldb_generic_dist,
	COMMUTATOR = '<->'
);
-- operator classes
CREATE OPERATOR CLASS dist_l2sq_ops
  DEFAULT FOR TYPE real[] USING hnsw AS
	OPERATOR 1 <-> (real[], real[]) FOR ORDER BY float_ops,
	FUNCTION 1 l2sq_dist(real[], real[]);

CREATE OPERATOR CLASS dist_cos_ops
	FOR TYPE real[] USING hnsw AS
	OPERATOR 1 <-> (real[], real[]) FOR ORDER BY float_ops,
	FUNCTION 1 cos_dist(real[], real[]);

CREATE OPERATOR CLASS dist_hamming_ops
	FOR TYPE integer[] USING hnsw AS
	OPERATOR 1 <-> (integer[], integer[]) FOR ORDER BY float_ops,
	FUNCTION 1 hamming_dist(integer[], integer[]);

-- conditionaly create operator class for vector type
DO $$DECLARE type_exists boolean;
BEGIN
	-- Check if the vector type exists and store the result in the 'type_exists' variable
	SELECT EXISTS (
    	SELECT 1
    	FROM pg_type
    	WHERE typname = 'vector'
	) INTO type_exists;

	IF type_exists THEN
	-- The type exists
	-- taken from pgvector so our index can work with pgvector types
		CREATE FUNCTION vector_l2sq_dist(vector, vector) RETURNS float8
			AS 'MODULE_PATHNAME' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

		DROP OPERATOR CLASS vector_l2_ops USING hnsw;

		CREATE OPERATOR CLASS dist_vec_l2sq_ops
			DEFAULT FOR TYPE vector USING hnsw AS
			OPERATOR 1 <-> (vector, vector) FOR ORDER BY float_ops,
			FUNCTION 1 vector_l2sq_dist(vector, vector);
	END IF;
END;
$$
LANGUAGE plpgsql;

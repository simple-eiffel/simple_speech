note
	description: "Integration test: simple_onnx working within simple_speech"
	author: "Larry Rix"

class
	TEST_ONNX_INTEGRATION

inherit
	TEST_SET_BASE

feature -- Tests: ONNX Foundation Classes

	test_simple_onnx_creation
			-- Test that simple_onnx.SIMPLE_ONNX can be instantiated from simple_speech.
		local
			l_onnx: SIMPLE_ONNX
		do
			create l_onnx.make
			check
				environment_created: l_onnx.environment /= Void
				cpu_provider_available: l_onnx.is_provider_available ("CPUExecutionProvider")
			end
		end

	test_onnx_shape_creation
			-- Test ONNX_SHAPE creation and queries.
		local
			l_onnx: SIMPLE_ONNX
			l_shape: ONNX_SHAPE
		do
			create l_onnx.make
			l_shape := l_onnx.create_shape (<<1, 77>>)
			check
				rank_correct: l_shape.rank = 2
				element_count: l_shape.element_count = 77
				dimension_0: l_shape.get_dimension (1) = 1
				dimension_1: l_shape.get_dimension (2) = 77
			end
		end

	test_onnx_data_type_float32
			-- Test float32 data type identification.
		local
			l_dtype: ONNX_DATA_TYPE
		do
			create l_dtype.make (1)
			check
				is_float: l_dtype.is_floating_point
				not_integer: not l_dtype.is_integer
				not_bool: not l_dtype.is_boolean
				size_correct: l_dtype.element_size = 4
				name_correct: l_dtype.name.same_string ("float32")
			end
		end

	test_onnx_tensor_float32
			-- Test float32 tensor creation and data handling.
		local
			l_onnx: SIMPLE_ONNX
			l_shape: ONNX_SHAPE
			l_tensor: ONNX_TENSOR
			l_data: ARRAY [REAL_32]
		do
			create l_onnx.make
			l_shape := l_onnx.create_shape (<<2, 3>>)
			l_tensor := l_onnx.create_tensor_float32 (l_shape)

			-- Create test data
			create l_data.make_filled (0.0, 1, 6)
			l_data [1] := 1.0
			l_data [2] := 2.0
			l_data [3] := 3.0
			l_data [4] := 4.0
			l_data [5] := 5.0
			l_data [6] := 6.0

			-- Set data
			l_tensor.set_data_from_array (l_data)

			-- Verify shape and type
			check
				shape_matches: l_tensor.shape = l_shape
				type_float32: l_tensor.data_type.type_id = 1
				element_count: l_tensor.element_count = 6
			end
		end

	test_onnx_result_success
			-- Test successful ONNX inference result.
		local
			l_onnx: SIMPLE_ONNX
			l_shape: ONNX_SHAPE
			l_tensor: ONNX_TENSOR
			l_result: ONNX_RESULT
		do
			create l_onnx.make
			l_shape := l_onnx.create_shape (<<1, 10>>)
			l_tensor := l_onnx.create_tensor_float32 (l_shape)

			create l_result.make_success (l_tensor)

			check
				is_success: l_result.is_success
				has_output: l_result.output_tensor /= Void
				no_error: l_result.error_code = 0
			end
		end

	test_onnx_result_failure
			-- Test failed ONNX inference result.
		local
			l_result: ONNX_RESULT
		do
			create l_result.make_failure (1, "Model failed to initialize")

			check
				is_failure: not l_result.is_success
				has_error_code: l_result.error_code = 1
				has_error_msg: l_result.error_message.same_string ("Model failed to initialize")
				no_output: l_result.output_tensor = Void
			end
		end

	test_onnx_provider_selection
			-- Test ONNX provider selection for execution.
		local
			l_cpu_provider, l_cuda_provider: ONNX_PROVIDER
		do
			create l_cpu_provider.make ("CPUExecutionProvider")
			check
				is_cpu: l_cpu_provider.is_cpu
				no_gpu: not l_cpu_provider.requires_gpu
			end

			create l_cuda_provider.make ("CUDAExecutionProvider")
			check
				not_cpu: not l_cuda_provider.is_cpu
				requires_gpu: l_cuda_provider.requires_gpu
			end
		end

	test_onnx_model_metadata
			-- Test model metadata structure.
		local
			l_model: ONNX_MODEL
		do
			l_model := create {ONNX_MODEL}.make ("point-e-base.onnx")
			l_model.set_input_count (1)
			l_model.set_output_count (1)
			l_model.set_opset_version (14)

			check
				path_set: l_model.model_path.same_string ("point-e-base.onnx")
				inputs_set: l_model.input_count = 1
				outputs_set: l_model.output_count = 1
				opset_set: l_model.opset_version = 14
			end
		end

	test_onnx_session_creation
			-- Test ONNX session creation with model.
		local
			l_model: ONNX_MODEL
			l_session: ONNX_SESSION
		do
			l_model := create {ONNX_MODEL}.make ("test.onnx")
			l_model.set_input_count (1)
			l_model.set_output_count (1)

			create l_session.make (l_model)

			check
				session_created: l_session /= Void
				model_set: l_session.model = l_model
				default_cpu_provider: l_session.provider.name.same_string ("CPUExecutionProvider")
				default_optimization: l_session.optimization_level = 2
			end
		end

	test_onnx_from_sherpa_context
			-- Test that simple_onnx works when called from sherpa-onnx context (simple_speech usage).
		local
			l_onnx: SIMPLE_ONNX
			l_shape: ONNX_SHAPE
			l_tensor: ONNX_TENSOR
			l_model: ONNX_MODEL
		do
			-- This simulates what simple_speech's sherpa_diarization could do
			create l_onnx.make

			-- Create segmentation model metadata
			l_model := l_onnx.load_model ("segmentation.onnx")
			check
				model_loaded: l_model /= Void
			end

			-- Create tensor for segmentation input
			l_shape := l_onnx.create_shape (<<1, 100>>)  -- Batch=1, Features=100
			l_tensor := l_onnx.create_tensor_float32 (l_shape)

			check
				tensor_ready: l_tensor /= Void
				shape_correct: l_tensor.shape.rank = 2
			end
		end

end

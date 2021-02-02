# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Domain::Metadata do
  let(:schema_major_version) { "1" }
  let(:schema_minor_version) { "0" }
  let(:ctx) { ShopifyCli::Context.new }
  let(:raw_json) do
    JSON.dump(
      {
        schemaVersions: {
          example: {
            major: schema_major_version, minor: schema_minor_version
          },
        },
      },
    )
  end

  describe ".new" do
    subject { Script::Layers::Domain::Metadata.new(schema_major_version, schema_minor_version) }

    it "should construct new Metadata" do
      assert_equal schema_major_version, subject.schema_major_version
      assert_equal schema_minor_version, subject.schema_minor_version
    end
  end

  describe ".create_from_json" do
    describe "with valid json" do
      subject { Script::Layers::Domain::Metadata.create_from_json(ctx, raw_json) }

      it "should construct new Metadata" do
        assert_equal schema_major_version, subject.schema_major_version
        assert_equal schema_minor_version, subject.schema_minor_version
      end
    end

    describe "with missing schemaVersions" do
      it "should raise an appropriate error" do
        assert_raises(::Script::Layers::Domain::Errors::MetadataValidationError) do
          Script::Layers::Domain::Metadata.create_from_json(ctx, '{}')
        end
      end
    end

    describe "with multiple EPs" do
      let(:raw_json_multiple_eps) do
        JSON.dump(
          {
            schemaVersions: {
              example1: {  major: schema_major_version, minor: schema_minor_version },
              example2: {  major: schema_major_version, minor: schema_minor_version },
            },
          },
        )
      end

      it "should raise an appropriate error" do
        assert_raises(::Script::Layers::Domain::Errors::MetadataValidationError) do
          Script::Layers::Domain::Metadata.create_from_json(ctx, raw_json_multiple_eps)
        end
      end
    end

    describe "with missing major version" do
      let(:raw_json_no_major) do
        JSON.dump(
          {
            schemaVersions: {
              example: { minor: schema_minor_version },
            },
          },
        )
      end

      it "should raise an appropriate error" do
        assert_raises(::Script::Layers::Domain::Errors::MetadataValidationError) do
          Script::Layers::Domain::Metadata.create_from_json(ctx, raw_json_no_major)
        end
      end
    end

    describe "with missing minor version" do
      let(:raw_json_no_minor) do
        JSON.dump(
          {
            schemaVersions: {
              example: { major: schema_major_version },
            },
          },
        )
      end

      it "should raise an appropriate error" do
        assert_raises(::Script::Layers::Domain::Errors::MetadataValidationError) do
          Script::Layers::Domain::Metadata.create_from_json(ctx, raw_json_no_minor)
        end
      end
    end
  end
end

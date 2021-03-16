# typed: false
# frozen_string_literal: true

module Homebrew
  module Livecheck
    module Strategy
      # The {ElectronBuilder} strategy fetches content at a URL and parses
      # it as an electron-builder appcast in YAML format.
      #
      # @api private
      class ElectronBuilder
        extend T::Sig

        NICE_NAME = "electron-builder"

        # A priority of zero causes livecheck to skip the strategy. We do this
        # for {ElectronBuilder} so we can selectively apply the strategy using
        # `strategy :electron_builder` in a `livecheck` block.
        PRIORITY = 0

        # The `Regexp` used to determine if the strategy applies to the URL.
        URL_MATCH_REGEX = %r{^https?://.+?/.+?\.yml}i.freeze

        # Whether the strategy can be applied to the provided URL.
        #
        # @param url [String] the URL to match against
        # @return [Boolean]
        sig { params(url: String).returns(T::Boolean) }
        def self.match?(url)
          URL_MATCH_REGEX.match?(url)
        end

        # Extract version information from page content.
        #
        # @param content [String] the content to check
        # @return [String]
        sig { params(content: String).returns(T.nilable(String)) }
        def self.version_from_content(content)
          require "yaml"

          return unless (item = YAML.safe_load(content))

          item["version"]
        end

        # Checks the content at the URL for new versions.
        #
        # @param url [String] the URL of the content to check
        # @param regex [Regexp] a regex used for matching versions in content
        # @return [Hash]
        sig { params(url: String, regex: T.nilable(Regexp)).returns(T::Hash[Symbol, T.untyped]) }
        def self.find_versions(url, regex = nil, &block)
          raise ArgumentError, "The #{T.must(name).demodulize} strategy does not support a regex." if regex

          match_data = { matches: {}, regex: regex, url: url }

          match_data.merge!(Strategy.page_content(url))
          content = match_data.delete(:content)

          if (item = version_from_content(content))
            match = if block
              block.call(item)&.to_s
            else
              item
            end

            match_data[:matches][match] = Version.new(match) if match
          end

          match_data
        end
      end
    end
  end
end

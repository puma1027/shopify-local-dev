module ShopifyCli
  ##
  # The `MethodObject` mixin can be included in any class that implements `call`
  # to ensure that
  #
  # * `call` will always return a `ShopifyCli::Result` by prepending a module
  #   that takes care of the result wrapping and
  # * a `to_proc` method that allows instances of this class to be passed as a
  #   block.
  #
  # For convenience, this mixin also adds the corresponding class methods:
  # `call` and `to_proc`. Method and result objects pair nicely as they greatly
  # simplify the creation of complex processing chains:
  #
  #   class Serialize
  #     include MethodObject
  #
  #     def call(attrs)
  #       attrs.to_json
  #     end
  #   end
  #
  #   class Deserialize
  #     include MethodObject
  #
  #     def call(json)
  #       JSON.parse(json)
  #     end
  #   end
  #
  #   Serialize
  #     .call(firstname: "John", lastname: "Doe")
  #     .then(&Deserialize)
  #     .map { |attrs| OpenStruct.new(attrs) }
  #     .unwrap(nil)
  #
  # While this example is contrived, it still illustrates some key advantages of
  # this programming paradigm:
  #
  # * chaining operations is as simple as repeatedly calling `then` or `map`,
  # * method objects don't have to be manually instantiated but can be
  #   constructed using the `&` operator,
  # * error handling is deferred until the result is unwrapped.
  #
  # Please see the section for `ShopifyCli::Result`,
  # `ShopifyCli::Result::Success`, and `ShopifyCli::Result::Failure` for more
  # information on the API of result objects.
  #
  module MethodObject
    module AutoCreateResultObject
      ##
      # invokes the original `call` implementation and wraps its return value
      # into a result object.
      #
      def call(*args, **kwargs)
        Result.wrap { super(*args, **kwargs) }.call
      end
    end

    module ClassMethods
      ##
      # creates a new instance and invokes `call`. Any positional argument
      # is forward to `call`. Keyword arguments are either forwarded to the
      # initializer or to `call`. If the keyword argument matches the name of
      # property, it is forwarded to the initializer, otherwise to call.
      #
      def call(*args, **kwargs)
        properties.keys.yield_self do |properties|
          new(**kwargs.slice(*properties))
            .call(*args, **kwargs.slice(*(kwargs.keys - properties)))
        end
      end

      ##
      # returns a proc that invokes `call` with all arguments it receives when
      # called itself.
      #
      def to_proc
        method(:call).to_proc
      end
    end

    ##
    # is invoked when this mixin is included into a class. This results in
    #
    # * including `SmartProperties`,
    # * prepending the result wrapping mechanism, and
    # * adding the class methods `.call` and `.to_proc`.
    #
    def self.included(method_object_implementation)
      method_object_implementation.prepend(AutoCreateResultObject)
      method_object_implementation.include(SmartProperties)
      method_object_implementation.extend(ClassMethods)
    end

    ##
    # returns a proc that invokes `call` with all arguments it receives when
    # called itself.
    #
    def to_proc
      method(:call).to_proc
    end
  end
end

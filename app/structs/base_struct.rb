class BaseStruct < Hashie::Trash
  include Hashie::Extensions::Coercion
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
  include Hashie::Extensions::IgnoreUndeclared
end

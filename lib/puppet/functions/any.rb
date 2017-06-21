# Runs a [lambda](http://docs.puppetlabs.com/puppet/latest/reference/lang_lambdas.html)
# repeatedly using each value in a data structure until the lambda returns a "truthy" value which
# makes the function return `true`, or if the end of the iteration is reached, false is returned.
#
# This function takes two mandatory arguments, in this order:
#
# 1. An array, hash, or other iterable object that the function will iterate over.
# 2. A lambda, which the function calls for each element in the first argument. It can
# request one or two parameters.
#
# @example Using the `any` function
#
# `$data.any |$parameter| { <PUPPET CODE BLOCK> }`
#
# or
#
# `any($data) |$parameter| { <PUPPET CODE BLOCK> }`
#
# @example Using the `any` function with an Array and a one-parameter lambda
#
# ~~~ puppet
# # For the array $data, run a lambda that checks if an unknown hash contains those keys
# $data = ["routers", "servers", "workstations"]
# $looked_up = lookup('somekey', Hash)
# notice $data.any |$item| { $looked_up[$item] }
# ~~~
#
# Would notice `true` if the looked up hash had a value that is neither `false` nor `undef` for at least
# one of the keys. That is, it is equivalent to the expression
# `$lookued_up[routers] || $looked_up[servers] || $looked_up[workstations]`.
#
# When the first argument is a `Hash`, Puppet passes each key and value pair to the lambda
# as an array in the form `[key, value]` and returns the original hash.
#
# @example Using the `each` function with a `Hash` and a one-parameter lambda
#
# ~~~ puppet
# # For the hash $data, run a lambda using each item as a key-value array that creates a
# # resource for each item.
# $data = {"rtr" => "Router", "svr" => "Server", "wks" => "Workstation"}
# $looked_up = lookup('somekey', Hash)
# notice $data.any |$item| { $looked_up[$item[0]] }
# ~~~
#
# Would notice `true` if the looked up hash had a value for one of the wanted key that is
# neither `false` nor `undef`.
#
# When the lambda accepts two arguments, the first argument gets the index in an array
# or the key from a hash, and the second argument the value.
#
#
# @example Using the `any` function with an array and a two-parameter lambda
#
# ~~~ puppet
# # Check if there is an even numbered index that has a non String value
# $data = [key1, 1, 2, 2]
# notice $data.any |$index, $value| { $index % 2 == 0 and $value !~ String }
# ~~~
#
# Would notice true as the index `2` is even and not a `String`
#
# For an general examples that demonstrates iteration, see the Puppet
# [iteration](https://docs.puppetlabs.com/puppet/latest/reference/lang_iteration.html)
# documentation.
#
# @since 5.2.0
#
Puppet::Functions.create_function(:any) do
  dispatch :any_Hash_2 do
    param 'Hash[Any, Any]', :hash
    block_param 'Callable[2,2]', :block
  end

  dispatch :any_Hash_1 do
    param 'Hash[Any, Any]', :hash
    block_param 'Callable[1,1]', :block
  end

  dispatch :any_Enumerable_2 do
    param 'Iterable', :enumerable
    block_param 'Callable[2,2]', :block
  end

  dispatch :any_Enumerable_1 do
    param 'Iterable', :enumerable
    block_param 'Callable[1,1]', :block
  end

  def any_Hash_1(hash)
    enumerator = hash.each_pair
    hash.size.times do
      return true if yield(enumerator.next)
    end
    false
  end

  def any_Hash_2(hash)
    enumerator = hash.each_pair
    hash.size.times do
      return true if yield(*enumerator.next)
    end
    false
  end

  def any_Enumerable_1(enumerable)
    enum = Puppet::Pops::Types::Iterable.asserted_iterable(self, enumerable)
      begin
        loop { return true if yield(enum.next) }
      rescue StopIteration
      end
    false
  end

  def any_Enumerable_2(enumerable)
    enum = Puppet::Pops::Types::Iterable.asserted_iterable(self, enumerable)
    index = 0
    begin
      loop do
        return true if yield(index, enum.next)
        index += 1
      end
    rescue StopIteration
    end
    return false
  end
end

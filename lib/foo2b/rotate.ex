use Bitwise

defmodule Bitmath do
  @moduledoc """
  bit wise rotate, takes bits ab and returns ba
    , three inputs: bit integer, bit rotation size, and size of bit integer
  """
  def rotate(x, n, size) do
    ((x >>> n) ^^^ (x <<< (size - n))) &&& 0xFFFFFFFFFFFFFFFF
  end

  def reverse_endian(a) do
    ((a>>>56)&&&0xff) ||| ((a>>>40)&&&0xff00) ||| ((a>>>24)&&&0xff0000) ||| ((a<<<24)&&&0xff0000000000) |||
    ((a>>>8)&&&0xff000000) ||| ((a<<<8)&&&0xff00000000) ||| ((a<<<40)&&& 0xff000000000000) ||| ((a<<<56)&&&0xff00000000000000)
  end
end

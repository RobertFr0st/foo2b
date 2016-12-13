defmodule BitmathTest do
  use ExUnit.Case, async: true

  describe "ab becomes ba" do
    test "only when rotate is half length" do
      assert Bitmath.rotate(0xAAAAAAAABBBBBBBB, 32, 64) == 0xBBBBBBBBAAAAAAAA
    end
  end


  describe "0x123456789ABCDEF0 becomes 0xF0DEBC9A78563412" do
    test "only when reverse endian is called" do
      assert Integer.to_string(Bitmath.reverse_endian(0x123456789ABCDEF0),16) == "F0DEBC9A78563412"
    end
  end
end

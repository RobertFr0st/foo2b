defmodule Foo2bBench do
  use Benchfella
  use Bitwise

  bench "Foo2b hash primative with default 64 byte digest" do
    Foo2b.foo2b('abc', 3)
  end

  bench "Foo2b hash primative with specified output size of 8" do
    Foo2b.foo2b('abc', 3, 8)
  end

  bench "Foo2b hash primative with specified output size of 7" do
    Foo2b.foo2b('abc', 3, 7)
  end

  bench "Compress hash primative" do
    Foo2b.compress({7640891576939301160, 13503953896175478587, 4354685564936845355, 11912009170470909681, 5840696475078001361, 11170449401992604703, 2270897969802886507, 6620516959819538809},{6513249,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},3,true,{7640891576956012808, 13503953896175478587, 4354685564936845355, 11912009170470909681, 5840696475078001361, 11170449401992604703, 2270897969802886507, 6620516959819538809})
  end
end

use Bitwise

defmodule Foo2b do
  def foo2b(message, input_bytes, output_half_bytes \\128, hash_bytes \\ 64, key \\ '') do
    key_bytes = length(key)
    data_blocks = blockify(message, key, input_bytes, key_bytes) 

    cond do
      input_bytes >= round(:math.pow(2, 128)) -> {"error", "input charlist exceeded maximum size of 2**128 bytes"}
      key_bytes > 64 -> {"error", "key exceeds maximum length of 64 bytes"}
      (hash_bytes > 64 or hash_bytes < 1) -> {"error", "hash size must be within range of 1 to 64"}
      (hash_bytes*2 < output_half_bytes) -> {"error", "hash size must be at least half the output length"}
      true -> foo2(data_blocks, input_bytes, key_bytes, hash_bytes, output_half_bytes)
    end
  end

  defp blockify(message, key, input_bytes, key_bytes) do
    unless(key_bytes == 0) do
      little_endianify(key) ++ little_endianify(message)
    else
      unless(input_bytes == 0) do
        little_endianify(message)
      else 
        little_endianify([0])
      end
    end
  end

  def little_endianify(message) do
    Enum.chunk(message, 8, 8, [0,0,0,0,0,0,0]) |> Enum.map(fn(x) -> List.to_string(x)
    |> Base.encode16 |> Integer.parse(16) |> elem(0) |> Bitmath.reverse_endian end)
    |> Enum.chunk(16, 16, [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])
  end

  defp block_count(key_bytes, input_bytes) do
    unless(key_bytes == 0 and input_bytes == 0) do
      round(Float.ceil(key_bytes / 128) + Float.ceil(input_bytes / 128))
    else
      1
    end
  end

  defp first_bytes(words, output_half_bytes) do
    Tuple.to_list(words)
    |> Enum.take(round(Float.ceil(output_half_bytes / 16)))
    |> Enum.map(fn(x) -> Bitmath.reverse_endian(x) end)
    |> Enum.map(fn(x) -> Integer.to_charlist(x, 16) end)
    |> Enum.map(fn(x) -> List.duplicate(?0, 16 - length(x)) ++ x end)
    |> List.flatten
    |> Enum.slice(0, output_half_bytes)
  end

  @doc """
    foo2 processes the padded data blocks into a hash_byte final hash value.
  """
  def foo2(data_blocks, input_bytes, key_bytes, hash_bytes, output_half_bytes) do
    #calculate block_count
    block_count = block_count(key_bytes, input_bytes)

    #set iv constant
    iv = [7640891576956012808, 13503953896175478587, 4354685564936845355, 11912009170470909681,
          5840696475078001361, 11170449401992604703, 2270897969802886507, 6620516959819538809]

    words = List.replace_at(iv, 0, (Enum.at(iv,0) ^^^ 0x01010000 ^^^ (key_bytes <<< 8) ^^^ hash_bytes) &&& 0xFFFFFFFFFFFFFFFF)
    |> List.to_tuple
    |> compress_blocks(data_blocks, List.to_tuple(iv), block_count)

    #final block
    if(key_bytes == 0) do
      compress(words, List.to_tuple(List.last(data_blocks)), input_bytes, true, List.to_tuple(iv)) |> first_bytes(output_half_bytes)
    else
      compress(words, List.to_tuple(List.last(data_blocks)), input_bytes + 128, true, List.to_tuple(iv)) |> first_bytes(output_half_bytes)
    end
  end

  defp compress_blocks(state, data_blocks, iv, block_count) do
    unless(List.first(data_blocks) == List.last(data_blocks)) do
      Enum.take(data_blocks, block_count - 1) |> Enum.map(fn(x) -> List.to_tuple(x) end)
      |> Enum.with_index |> Enum.reduce(state, fn({block, i}, acc) -> compress(acc, block, (i + 1) * 128, false, iv) end)
    else
      state
    end
  end

  @doc """
    Compress compresses the states list, the message block list.
    The last block of message block is padded with zeros to full block size if required.
    "offset_counter" is a 128 bits.  The final flag is used to indicate if final message_block.
    A local list named tmp is used to keep track of state.  Compress returns a new state list.
    Since this is for foo2b it is 12 rounds. 
  """
  def compress({s0,s1,s2,s3,s4,s5,s6,s7}, block, offset_counter, final_flag, {v0,v1,v2,v3,v4,v5,v6,v7}) do
    #initilize local working vector
    hash = {s0,s1,s2,s3,s4,s5,s6,
      s7,v0,v1,v2,v3,v4 ^^^ rem(offset_counter, round(:math.pow(2, 64))),v5 ^^^ (offset_counter >>> 64),v6,v7}

    if(final_flag) do
      put_elem(hash, 14, elem(hash,14) ^^^ 0xFFFFFFFFFFFFFFFF)
      |> multiround_mix(block) |> merge_tuples({s0,s1,s2,s3,s4,s5,s6,s7})
    else 
      multiround_mix(hash, block) |> merge_tuples({s0,s1,s2,s3,s4,s5,s6,s7})
    end
  end

  defp merge_tuples(mixed_hash, states) do
    {merge_tuple(states, mixed_hash, 0), merge_tuple(states, mixed_hash, 1), merge_tuple(states, mixed_hash, 2),
    merge_tuple(states, mixed_hash, 3), merge_tuple(states, mixed_hash, 4), merge_tuple(states, mixed_hash, 5),
    merge_tuple(states, mixed_hash, 6), merge_tuple(states, mixed_hash, 7)}
  end

  defp merge_tuple(states, mixed_hash, i) do
    elem(states,i) ^^^ elem(mixed_hash, i) ^^^ elem(mixed_hash, i + 8)
  end

  defp multiround_mix(hash, block) do
    #define sigma constant
    sigma ={{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
           {14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3},
           {11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4},
           {7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8},
           {9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13},
           {2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9},
           {12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11},
           {13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10},
           {6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5},
           {10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0}}

    mix_round(hash, elem(sigma, 0), block)
    |> mix_round(elem(sigma, 1), block)
    |> mix_round(elem(sigma, 2), block)
    |> mix_round(elem(sigma, 3), block)
    |> mix_round(elem(sigma, 4), block)
    |> mix_round(elem(sigma, 5), block)
    |> mix_round(elem(sigma, 6), block)
    |> mix_round(elem(sigma, 7), block)
    |> mix_round(elem(sigma, 8), block)
    |> mix_round(elem(sigma, 9), block)
    |> mix_round(elem(sigma, 0), block)
    |> mix_round(elem(sigma, 1), block)
  end

  defp mix_round({h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15}, s, message_block) do
    {i0,i4,i8,i12} = mix(h0, h4, h8, h12, elem(message_block,elem(s,0)), elem(message_block,elem(s,1)))
    {i1,i5,i9,i13} = mix(h1, h5, h9, h13, elem(message_block,elem(s,2)), elem(message_block,elem(s,3)))
    {i2,i6,i10,i14} = mix(h2, h6, h10, h14, elem(message_block,elem(s,4)), elem(message_block,elem(s,5)))
    {i3,i7,i11,i15} = mix(h3, h7, h11, h15, elem(message_block,elem(s,6)), elem(message_block,elem(s,7)))

    {f0,f5,f10,f15} = mix(i0, i5, i10, i15, elem(message_block,elem(s,8)), elem(message_block,elem(s,9)))
    {f1,f6,f11,f12} = mix(i1, i6, i11, i12, elem(message_block,elem(s,10)),elem(message_block,elem(s,11)))
    {f2,f7,f8,f13} = mix(i2, i7, i8, i13, elem(message_block,elem(s,12)),elem(message_block,elem(s,13)))
    {f3,f4,f9,f14} = mix(i3, i4, i9, i14, elem(message_block,elem(s,14)),elem(message_block,elem(s,15)))

    {f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15}
  end

  @doc """
    Mix mixes two input words x and y, into four words indexed by i, j, k, l in the working list.
    The full modified list is returned.  The rotation constants are R1, R2, R3, R4: 32, 24, 16, 63.  Since this is foo2b w is 64
  """
  def mix(a, b, c, d, x, y) do
    mix_half({a,b,c,d}, x, 32, 24) |> mix_half(y, 16, 63)
  end

  defp mix_half(block, word, ra, rb) do
    a = rem(elem(block, 0) + elem(block, 1) + word, round(:math.pow(2, 64)))
    d = Bitmath.rotate(elem(block, 3) ^^^ a, ra, 64)
    c = rem(elem(block, 2) + d, round(:math.pow(2, 64)))
    b = Bitmath.rotate(elem(block, 1) ^^^ c, rb, 64)
    {a, b, c, d}
  end
end

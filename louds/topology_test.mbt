///|
test "LOUDS navigates a mixed ordered tree" {
  // 0 -> [1,2,3], 1 -> [4,5], 3 -> [6], remaining nodes are leaves.
  let topology = from_degrees([3, 2, 0, 1, 0, 0, 0])
  assert_eq(topology.node_count(), 7)
  assert_eq(topology.edge_count(), 6)
  assert_eq(topology.bit_length(), 13)
  assert_eq(topology.to_degrees(), [3, 2, 0, 1, 0, 0, 0])
  assert_eq(topology.parent(0), None)
  assert_eq(topology.children(0), [1, 2, 3])
  assert_eq(topology.children(1), [4, 5])
  assert_eq(topology.children(2), [])
  assert_eq(topology.children(3), [6])
  assert_eq(topology.parent(4), Some(1))
  assert_eq(topology.parent(6), Some(3))
  assert_eq(topology.child(0, 2), Some(3))
  assert_eq(topology.child(0, 3), None)
  assert_true(topology.is_leaf(5))
}

///|
test "LOUDS supports a root-only tree and long chain" {
  let root = from_degrees([0])
  assert_eq(root.to_degrees(), [0])
  assert_true(root.is_leaf(0))
  let chain = from_degrees([1, 1, 1, 0])
  assert_eq(chain.children(0), [1])
  assert_eq(chain.children(1), [2])
  assert_eq(chain.children(2), [3])
  assert_eq(chain.parent(3), Some(2))
  assert_eq(
    from_bitvector(@bitvector.from_words(chain.packed_words(), 7)).to_degrees(),
    [1, 1, 1, 0],
  )
}

///|
test "LOUDS rejects impossible degree sequences and node numbers" {
  let invalid : Array[Array[Int]] = [[], [-1], [0, 0], [2, 0], [1, 0, 0]]
  for degrees in invalid {
    ignore(from_degrees(degrees)) catch {
      @support.SuccinctError::InvalidArgument(..) => ()
      @support.SuccinctError::InvalidSequence(..) => ()
      _ => fail("expected invalid topology")
    }
  }
  let topology = from_degrees([0])
  ignore(topology.degree(1)) catch {
    @support.SuccinctError::OutOfRange(..) => ()
    _ => fail("expected node range error")
  }
}

///|
test "LOUDS rejects an impossible huge degree before allocating its bits" {
  ignore(from_degrees([2147483647])) catch {
    @support.SuccinctError::InvalidSequence(index~, ..) => assert_eq(index, 0)
    _ => fail("expected impossible edge-count rejection")
  }
}

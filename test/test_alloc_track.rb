require 'test/unit'
require 'alloc_track/alloc_track'

class TestAllocTrack < Test::Unit::TestCase
  def test_allocate
    AllocTrack.start
    100.times { Object.new }
    assert_operator AllocTrack.delta, :>=, 100
    AllocTrack.stop
  end

  def test_allocate_with_gc
    AllocTrack.start
    100.times { Object.new }
    GC.start
    assert_operator AllocTrack.alloc, :>=, 100
    assert_operator AllocTrack.delta, :<, 100
    assert_operator AllocTrack.free, :>=, 100
    AllocTrack.stop
  end

  def test_thread_not_included
    AllocTrack.start
    t = Thread.new do
      100.times { Object.new }
    end
    t.join
    assert_operator AllocTrack.delta, :<, 100
    AllocTrack.stop
  end

  def test_limit_with_no_block
    assert_raise ArgumentError do
      AllocTrack.limit 100
    end
  end

  def test_limit_with_non_number
    assert_raise ArgumentError do
      AllocTrack.limit "foo" do
      end
    end
  end

  def test_limit_raises
    assert_raise AllocTrack::LimitExceeded do
      AllocTrack.limit 10 do
        200.times { Object.new }
      end
    end
  end

  def test_within_limit
    assert_nothing_raised do
      AllocTrack.limit 100 do
        50.times { Object.new }
      end
    end
  end

  def test_limit_exception_stops
    assert_raise AllocTrack::LimitExceeded do
      AllocTrack.limit 100 do
        200.times { Object.new }
      end
    end
    refute AllocTrack.started?
  end
end

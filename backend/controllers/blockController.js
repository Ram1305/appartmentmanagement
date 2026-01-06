const Block = require('../models/Block');

// @desc    Get all blocks
// @route   GET /api/blocks
// @access  Public (can be protected later)
const getAllBlocks = async (req, res) => {
  try {
    const blocks = await Block.find().sort({ name: 1 });
    res.json({
      success: true,
      count: blocks.length,
      blocks,
    });
  } catch (error) {
    console.error('Get blocks error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Get single block
// @route   GET /api/blocks/:id
// @access  Public
const getBlock = async (req, res) => {
  try {
    const block = await Block.findById(req.params.id);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    res.json({
      success: true,
      block,
    });
  } catch (error) {
    console.error('Get block error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Create a new block
// @route   POST /api/blocks
// @access  Public (can be protected later)
const createBlock = async (req, res) => {
  try {
    const { name } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Block name is required',
      });
    }

    // Check if block already exists
    const blockExists = await Block.findOne({ name: name.toUpperCase() });

    if (blockExists) {
      return res.status(400).json({
        success: false,
        error: 'Block already exists',
      });
    }

    const block = await Block.create({
      name: name.toUpperCase(),
      floors: [],
    });

    res.status(201).json({
      success: true,
      message: 'Block created successfully',
      block,
    });
  } catch (error) {
    console.error('Create block error:', error);
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'Block already exists',
      });
    }
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Add floor to block
// @route   POST /api/blocks/:id/floors
// @access  Public
const addFloor = async (req, res) => {
  try {
    const { number, rooms } = req.body;

    if (!number) {
      return res.status(400).json({
        success: false,
        error: 'Floor number is required',
      });
    }

    const block = await Block.findById(req.params.id);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    // Check if floor already exists
    const floorExists = block.floors.find(f => f.number === number);
    if (floorExists) {
      return res.status(400).json({
        success: false,
        error: 'Floor already exists',
      });
    }

    // Create rooms array
    const roomsArray = rooms || [];
    const formattedRooms = roomsArray.map(room => ({
      number: room.number || room,
      type: room.type || '1BHK',
    }));

    block.floors.push({
      number,
      rooms: formattedRooms,
    });

    await block.save();

    res.status(201).json({
      success: true,
      message: 'Floor added successfully',
      block,
    });
  } catch (error) {
    console.error('Add floor error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update block
// @route   PUT /api/blocks/:id
// @access  Public
const updateBlock = async (req, res) => {
  try {
    const block = await Block.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true,
      }
    );

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    res.json({
      success: true,
      message: 'Block updated successfully',
      block,
    });
  } catch (error) {
    console.error('Update block error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete block
// @route   DELETE /api/blocks/:id
// @access  Public
const deleteBlock = async (req, res) => {
  try {
    const block = await Block.findByIdAndDelete(req.params.id);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    res.json({
      success: true,
      message: 'Block deleted successfully',
    });
  } catch (error) {
    console.error('Delete block error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Add room to floor
// @route   POST /api/blocks/:blockId/floors/:floorId/rooms
// @access  Public
const addRoom = async (req, res) => {
  try {
    const { blockId, floorId } = req.params;
    const { number, type } = req.body;

    if (!number || !type) {
      return res.status(400).json({
        success: false,
        error: 'Room number and type are required',
      });
    }

    const block = await Block.findById(blockId);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    // Find the floor
    const floor = block.floors.id(floorId);
    if (!floor) {
      return res.status(404).json({
        success: false,
        error: 'Floor not found',
      });
    }

    // Check if room number already exists in this floor
    const roomExists = floor.rooms.find(r => r.number === number);
    if (roomExists) {
      return res.status(400).json({
        success: false,
        error: 'Room number already exists in this floor',
      });
    }

    // Add room to floor
    floor.rooms.push({
      number,
      type,
    });

    await block.save();

    res.status(201).json({
      success: true,
      message: 'Room added successfully',
      block,
    });
  } catch (error) {
    console.error('Add room error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Update floor
// @route   PUT /api/blocks/:blockId/floors/:floorId
// @access  Public
const updateFloor = async (req, res) => {
  try {
    const { blockId, floorId } = req.params;
    const { number } = req.body;

    if (!number) {
      return res.status(400).json({
        success: false,
        error: 'Floor number is required',
      });
    }

    const block = await Block.findById(blockId);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    const floor = block.floors.id(floorId);
    if (!floor) {
      return res.status(404).json({
        success: false,
        error: 'Floor not found',
      });
    }

    // Check if new floor number already exists (excluding current floor)
    const floorExists = block.floors.find(
      f => f.number === number && f._id.toString() !== floorId
    );
    if (floorExists) {
      return res.status(400).json({
        success: false,
        error: 'Floor number already exists',
      });
    }

    floor.number = number;
    await block.save();

    res.json({
      success: true,
      message: 'Floor updated successfully',
      block,
    });
  } catch (error) {
    console.error('Update floor error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Delete floor
// @route   DELETE /api/blocks/:blockId/floors/:floorId
// @access  Public
const deleteFloor = async (req, res) => {
  try {
    const { blockId, floorId } = req.params;

    const block = await Block.findById(blockId);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    const floor = block.floors.id(floorId);
    if (!floor) {
      return res.status(404).json({
        success: false,
        error: 'Floor not found',
      });
    }

    block.floors.pull(floorId);
    await block.save();

    res.json({
      success: true,
      message: 'Floor deleted successfully',
      block,
    });
  } catch (error) {
    console.error('Delete floor error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

// @desc    Toggle block active status
// @route   PUT /api/blocks/:id/toggle-active
// @access  Public
const toggleBlockActive = async (req, res) => {
  try {
    const block = await Block.findById(req.params.id);

    if (!block) {
      return res.status(404).json({
        success: false,
        error: 'Block not found',
      });
    }

    block.isActive = !block.isActive;
    await block.save();

    res.json({
      success: true,
      message: `Block ${block.isActive ? 'activated' : 'deactivated'} successfully`,
      block,
    });
  } catch (error) {
    console.error('Toggle block active error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Server error',
    });
  }
};

module.exports = {
  getAllBlocks,
  getBlock,
  createBlock,
  addFloor,
  addRoom,
  updateBlock,
  updateFloor,
  deleteBlock,
  deleteFloor,
  toggleBlockActive,
};


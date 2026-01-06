const express = require('express');
const router = express.Router();
const {
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
} = require('../controllers/blockController');

// @route   GET /api/blocks
// @desc    Get all blocks
// @access  Public
router.get('/', getAllBlocks);

// @route   GET /api/blocks/:id
// @desc    Get single block
// @access  Public
router.get('/:id', getBlock);

// @route   POST /api/blocks
// @desc    Create a new block
// @access  Public
router.post('/', createBlock);

// @route   POST /api/blocks/:id/floors
// @desc    Add floor to block
// @access  Public
router.post('/:id/floors', addFloor);

// @route   PUT /api/blocks/:id
// @desc    Update block
// @access  Public
router.put('/:id', updateBlock);

// @route   DELETE /api/blocks/:id
// @desc    Delete block
// @access  Public
router.delete('/:id', deleteBlock);

// @route   POST /api/blocks/:blockId/floors/:floorId/rooms
// @desc    Add room to floor
// @access  Public
router.post('/:blockId/floors/:floorId/rooms', addRoom);

// @route   PUT /api/blocks/:blockId/floors/:floorId
// @desc    Update floor
// @access  Public
router.put('/:blockId/floors/:floorId', updateFloor);

// @route   DELETE /api/blocks/:blockId/floors/:floorId
// @desc    Delete floor
// @access  Public
router.delete('/:blockId/floors/:floorId', deleteFloor);

// @route   PUT /api/blocks/:id/toggle-active
// @desc    Toggle block active status
// @access  Public
router.put('/:id/toggle-active', toggleBlockActive);

module.exports = router;


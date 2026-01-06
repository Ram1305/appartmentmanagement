const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
  number: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    required: true,
    enum: ['1BHK', '2BHK', '3BHK', '4BHK'],
  },
}, {
  _id: true,
  timestamps: false,
});

const floorSchema = new mongoose.Schema({
  number: {
    type: String,
    required: true,
  },
  rooms: [roomSchema],
}, {
  _id: true,
  timestamps: false,
});

const blockSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Block name is required'],
      unique: true,
      trim: true,
      uppercase: true,
      maxlength: [1, 'Block name must be a single letter'],
    },
    floors: [floorSchema],
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Transform _id to id in JSON response
blockSchema.set('toJSON', {
  transform: function (doc, ret) {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    
    // Transform floors
    if (ret.floors) {
      ret.floors = ret.floors.map(floor => {
        floor.id = floor._id.toString();
        delete floor._id;
        
        // Transform rooms
        if (floor.rooms) {
          floor.rooms = floor.rooms.map(room => {
            room.id = room._id.toString();
            delete room._id;
            return room;
          });
        }
        
        return floor;
      });
    }
    
    return ret;
  },
});

module.exports = mongoose.model('Block', blockSchema);


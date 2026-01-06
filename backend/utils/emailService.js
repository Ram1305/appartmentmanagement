const nodemailer = require('nodemailer');

// Gmail SMTP configuration
const transporter = nodemailer.createTransport({
  service: 'gmail',
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.EMAIL_PORT) || 587,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS ? process.env.EMAIL_PASS.replace(/\s+/g, '') : '', // Remove spaces from app password
  },
  tls: {
    rejectUnauthorized: false, // For development, set to true in production
  },
});

const sendOTPEmail = async (email, otp) => {
  try {
    console.log('=== SENDING OTP EMAIL ===');
    console.log('To:', email);
    console.log('From:', process.env.EMAIL_USER);
    console.log('OTP:', otp);
    
    // Verify transporter configuration
    await transporter.verify();
    console.log('✓ Email server connection verified');
    
    const mailOptions = {
      from: `"Apartment Management" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'OTP for Apartment Management System',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
            <h2 style="color: white; margin: 0;">Apartment Management System</h2>
          </div>
          <div style="background-color: #ffffff; padding: 30px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 10px 10px;">
            <p style="font-size: 16px; color: #333;">Your OTP for verification is:</p>
            <div style="background: linear-gradient(135deg, #f0f0f0 0%, #e0e0e0 100%); padding: 25px; text-align: center; font-size: 36px; font-weight: bold; color: #1E3A8A; margin: 25px 0; border-radius: 8px; letter-spacing: 5px;">
              ${otp}
            </div>
            <p style="font-size: 14px; color: #666; margin-top: 20px;">This OTP will expire in 10 minutes.</p>
            <p style="font-size: 12px; color: #999; margin-top: 20px; border-top: 1px solid #e0e0e0; padding-top: 20px;">If you didn't request this OTP, please ignore this email.</p>
          </div>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✓ Email sent successfully');
    console.log('Message ID:', info.messageId);
    return true;
  } catch (error) {
    console.error('✗ Error sending email:', error.message);
    console.error('Error details:', error);
    if (error.code === 'EAUTH') {
      console.error('Authentication failed. Please check your EMAIL_USER and EMAIL_PASS in .env file');
    }
    return false;
  }
};

const sendPasswordResetEmail = async (email, otp) => {
  try {
    console.log('=== SENDING PASSWORD RESET EMAIL ===');
    console.log('To:', email);
    console.log('From:', process.env.EMAIL_USER);
    console.log('OTP:', otp);
    
    const mailOptions = {
      from: `"Apartment Management" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Password Reset OTP - Apartment Management System',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #DC2626 0%, #EF4444 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
            <h2 style="color: white; margin: 0;">Password Reset Request</h2>
          </div>
          <div style="background-color: #ffffff; padding: 30px; border: 1px solid #e0e0e0; border-top: none; border-radius: 0 0 10px 10px;">
            <p style="font-size: 16px; color: #333;">You requested to reset your password. Your OTP is:</p>
            <div style="background: linear-gradient(135deg, #f0f0f0 0%, #e0e0e0 100%); padding: 25px; text-align: center; font-size: 36px; font-weight: bold; color: #DC2626; margin: 25px 0; border-radius: 8px; letter-spacing: 5px;">
              ${otp}
            </div>
            <p style="font-size: 14px; color: #666; margin-top: 20px;">This OTP will expire in 10 minutes.</p>
            <p style="font-size: 12px; color: #999; margin-top: 20px; border-top: 1px solid #e0e0e0; padding-top: 20px;">If you didn't request this, please ignore this email.</p>
          </div>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✓ Password reset email sent successfully');
    console.log('Message ID:', info.messageId);
    return true;
  } catch (error) {
    console.error('✗ Error sending password reset email:', error.message);
    console.error('Error details:', error);
    if (error.code === 'EAUTH') {
      console.error('Authentication failed. Please check your EMAIL_USER and EMAIL_PASS in .env file');
    }
    return false;
  }
};

module.exports = {
  sendOTPEmail,
  sendPasswordResetEmail,
};


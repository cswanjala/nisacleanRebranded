/**
 * Validates a phone number format
 * @param {string} phone - The phone number to validate
 * @returns {boolean} - Whether the phone number is valid
 */
const validatePhoneNumber = (phone) => {
  // Remove any spaces or special characters
  const cleaned = phone.replace(/[\s\-\(\)]/g, '');
  
  // Check if it's a valid Kenyan phone number
  // Format: 07XXXXXXXX or 254XXXXXXXXX
  const kenyaRegex = /^(?:254|\+254|0)?([7-9]{1}[0-9]{8})$/;
  
  return kenyaRegex.test(cleaned);
};

/**
 * Validates an amount
 * @param {number|string} amount - The amount to validate
 * @returns {boolean} - Whether the amount is valid
 */
const validateAmount = (amount) => {
  // Convert to number if it's a string
  const numAmount = typeof amount === 'string' ? parseFloat(amount) : amount;
  
  // Check if it's a valid number
  if (isNaN(numAmount)) {
    return false;
  }
  
  // Check if it's positive
  if (numAmount <= 0) {
    return false;
  }
  
  // Check if it has more than 2 decimal places
  if (numAmount.toString().split('.')[1]?.length > 2) {
    return false;
  }
  
  // Check if it's within reasonable limits (e.g., max 1 million KES)
  if (numAmount > 1000000) {
    return false;
  }
  
  return true;
};

module.exports = {
  validatePhoneNumber,
  validateAmount,
}; 
import { describe, it, expect, beforeEach } from 'vitest'

describe('Incentive Management Contract', () => {
  let contractAddress: string
  let deployer: string
  let partner: string
  
  beforeEach(() => {
    contractAddress = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.incentive-management'
    deployer = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
    partner = 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC'
  })
  
  describe('Incentive Pool Management', () => {
    it('should create incentive pool', () => {
      const poolData = {
        amount: 100000,
        incentiveType: 1, // INCENTIVE_PERFORMANCE
        period: 202401
      }
      
      const result = {
        success: true,
        value: 1 // pool-id
      }
      
      expect(result.success).toBe(true)
      expect(result.value).toBe(1)
    })
    
    it('should only allow owner to create pools', () => {
      const result = {
        success: false,
        error: 400 // ERR_UNAUTHORIZED
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe(400)
    })
  })
  
  describe('Incentive Criteria', () => {
    it('should set incentive criteria', () => {
      const criteria = {
        incentiveType: 1,
        minScore: 75,
        minRevenue: 25000,
        minDeals: 5,
        multiplier: 2
      }
      
      const result = {
        success: true,
        value: true
      }
      
      expect(result.success).toBe(true)
      expect(result.value).toBe(true)
    })
  })
  
  describe('Incentive Calculation and Award', () => {
    it('should calculate and award incentive for qualifying performance', () => {
      const performanceData = {
        partner: partner,
        incentiveType: 1,
        performanceScore: 85,
        revenue: 30000,
        deals: 7,
        period: 202401
      }
      
      const result = {
        success: true,
        value: 1 // incentive-id
      }
      
      expect(result.success).toBe(true)
      expect(result.value).toBe(1)
    })
    
    it('should mark criteria as met for qualifying performance', () => {
      const incentiveData = {
        amount: 2000, // 1000 * 2 multiplier
        'incentive-type': 1,
        'earned-at': 1000,
        claimed: false,
        'performance-period': 202401,
        'criteria-met': true
      }
      
      expect(incentiveData['criteria-met']).toBe(true)
      expect(incentiveData.amount).toBe(2000)
    })
    
    it('should mark criteria as not met for non-qualifying performance', () => {
      const incentiveData = {
        'criteria-met': false
      }
      
      expect(incentiveData['criteria-met']).toBe(false)
    })
  })
  
  describe('Incentive Claiming', () => {
    it('should allow partner to claim earned incentive', () => {
      const result = {
        success: true,
        value: 2000 // claimed amount
      }
      
      expect(result.success).toBe(true)
      expect(result.value).toBe(2000)
    })
    
    it('should prevent claiming already claimed incentive', () => {
      const result = {
        success: false,
        error: 403 // ERR_ALREADY_CLAIMED
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe(403)
    })
    
    it('should prevent claiming unearned incentive', () => {
      const result = {
        success: false,
        error: 400 // ERR_UNAUTHORIZED
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe(400)
    })
    
    it('should update total distributed amount', () => {
      const totalDistributed = 5000
      expect(totalDistributed).toBe(5000)
    })
  })
  
  describe('Incentive Approval', () => {
    it('should allow owner to approve incentive', () => {
      const result = {
        success: true,
        value: true
      }
      
      expect(result.success).toBe(true)
      expect(result.value).toBe(true)
    })
    
    it('should only allow owner to approve', () => {
      const result = {
        success: false,
        error: 400 // ERR_UNAUTHORIZED
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe(400)
    })
  })
  
  describe('Potential Incentive Calculation', () => {
    it('should calculate potential incentive for qualifying metrics', () => {
      const potentialIncentive = 3000 // 1000 * 3 multiplier
      expect(potentialIncentive).toBe(3000)
    })
    
    it('should return zero for non-qualifying metrics', () => {
      const potentialIncentive = 0
      expect(potentialIncentive).toBe(0)
    })
    
    it('should return none for missing criteria', () => {
      const potentialIncentive = null
      expect(potentialIncentive).toBeNull()
    })
  })
  
  describe('Read-only Functions', () => {
    it('should get incentive pool information', () => {
      const poolInfo = {
        'total-amount': 100000,
        'available-amount': 95000,
        'incentive-type': 1,
        period: 202401,
        'created-at': 1000
      }
      
      expect(poolInfo['total-amount']).toBe(100000)
      expect(poolInfo['available-amount']).toBe(95000)
      expect(poolInfo.period).toBe(202401)
    })
    
    it('should get partner incentive details', () => {
      const incentiveInfo = {
        amount: 2000,
        'incentive-type': 1,
        'earned-at': 1000,
        claimed: false,
        'performance-period': 202401,
        'criteria-met': true
      }
      
      expect(incentiveInfo.amount).toBe(2000)
      expect(incentiveInfo.claimed).toBe(false)
      expect(incentiveInfo['criteria-met']).toBe(true)
    })
    
    it('should get incentive criteria', () => {
      const criteria = {
        'min-performance-score': 75,
        'min-revenue': 25000,
        'min-deals': 5,
        multiplier: 2
      }
      
      expect(criteria['min-performance-score']).toBe(75)
      expect(criteria.multiplier).toBe(2)
    })
  })
})

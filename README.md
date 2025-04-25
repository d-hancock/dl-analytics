# CareTend Analytics Data Platform

## Overview

This repository contains the analytics data model for CareTend, providing a structured approach to reporting and analysis. The platform follows a layered architecture, transforming raw OLTP data into business-ready KPIs.

## 🔄 Schema Refactoring Update - April 2025

**Important**: The data model has been refactored to align with the correct CareTend OLTP database schema. This refactoring ensures data accuracy and consistency across all analytics views.

### Key Changes

1. **Corrected Table References**
   - Fixed incorrect schema references (e.g., `OLTP_DB.Prescription.PatientOrder` instead of `OLTP_DB.Encounter.PatientOrder`)
   - Updated table names to match actual OLTP DB structure

2. **Fixed Column Names**
   - Standardized primary keys to use `Id` instead of various `*Key` patterns
   - Updated column names to match documented schema

3. **Rebuilt Join Logic**
   - Corrected relationship patterns between tables
   - Implemented consistent active record filtering

### Documentation

For detailed information about the refactoring:

- [Schema Refactoring Summary](/notes/schema_refactoring_summary.md) - Overview of changes made
- [Schema Mapping Before/After](/notes/schema_mapping_before_after.md) - Detailed column mapping
- [Refactored Data Model](/documentation/refactored_data_model.md) - Complete data model documentation

## Architecture

The analytics platform follows a multi-layered approach:

1. **Staging Layer** (`stg_*`) - Direct 1:1 representation of source tables
2. **Intermediate Layer** (`int_*`) - Business logic and dimensional modeling 
3. **Marts Layer** (`finance.*`) - Purpose-built views for specific business domains
4. **Presentation Layer** - Final views for dashboards and reporting

## Core KPIs

The platform supports these key business metrics:

- **Referrals**: Patient referral activity tracking
- **New Starts**: New patient acquisition metrics
- **Discharged Patients**: Patient discharge analytics
- **Drug Revenue**: Revenue from drug-related claims
- **Expected Revenue Per Day**: Revenue forecasting

## Getting Started

To explore the analytics model:

1. Review the refactored data model documentation
2. Explore the layer-specific READMEs for conventions and examples
3. Use the mart views for domain-specific analysis

## Project Structure

```
models/
  ├── staging/        # 1:1 mappings of source tables
  ├── intermediate/   # Business logic and dimensions
  ├── marts/          # Domain-specific analytics
  │   └── finance/    # Financial reporting views
  └── presentation/   # Dashboard-ready views
documentation/        # Architecture docs
notes/                # Reference materials
```
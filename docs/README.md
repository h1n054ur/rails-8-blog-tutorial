# Rails 8 Tutorial Blog - Documentation Guide

Welcome to the comprehensive documentation for our Rails 8 tutorial blog application. This directory serves as both the development hub and learning resource for building a complete Rails application with beginner-friendly explanations.

## Purpose of This Documentation

This `docs/` folder contains:
- **Development workflow and progress tracking**
- **Detailed implementation explanations for Rails beginners**
- **Step-by-step tutorials and learning materials**
- **Rails 8 reference documentation and best practices**

## Tutorial Development Documentation

### Core Workflow Files

#### `/CLAUDE.md` (Project Root)
Master workflow document defining our beginner-focused development approach:
- AI assistant role and documentation standards
- Detailed commenting requirements for educational value
- Step-by-step development process
- Teaching philosophy and learning objectives

#### `todo.md`
Living task list organized by development phases:
- Current priorities and completion status
- Detailed acceptance criteria for each task
- Progress tracking and phase management

#### `journal/` Directory
Versioned development journals documenting implementation decisions:
- `journal-v1.md` - Current development session (500 lines max)
- Detailed explanations of why specific approaches were chosen
- Learning points for Rails beginners
- Troubleshooting notes and common pitfalls

### Phase-Based Development

Development is organized into phases, each with dedicated documentation:
- `phase-1.md` - Setup & Documentation Workflow
- `phase-2.md` - Public Interface Development
- `phase-3.md` - Admin Authentication System
- `phase-4.md` - Admin CRUD Operations
- `phase-5.md` - Documentation & Deployment

Each phase includes learning objectives, implementation plans, and testing strategies.

## Rails 8 Reference Documentation

**[Rails 8 Documentation Suite](./rails8-docs/README.md)**

Complete Rails 8 feature documentation used as our **only external reference**:
- Core Rails features and components
- Rails 8-specific enhancements and new features
- Setup, configuration, and deployment strategies
- Security, testing, and performance optimization
- Code examples and best practices

**Why Local Documentation Only?**
- Ensures version consistency with our Rails 8 application
- No network dependency for development
- Focused learning without external confusion
- Professional development practice

## Getting Started

### For Rails Beginners Following This Tutorial

1. **Start Here**: Read `/CLAUDE.md` to understand our development approach
2. **Check Progress**: Review `todo.md` to see current status
3. **Understand Decisions**: Read latest journal entry for recent implementation choices
4. **Follow Phases**: Work through `phase-*.md` files systematically
5. **Reference Rails**: Use `rails8-docs/` when you need to understand Rails concepts

### For Continuing Development

1. **Context Review**: Read `todo.md` and latest journal entry
2. **Reference Check**: Consult `rails8-docs/` for Rails 8 guidance
3. **Implementation**: Code with extensive beginner-focused comments
4. **Documentation**: Update journal with detailed explanations
5. **Task Management**: Mark completed tasks and add discoveries

## Key Documentation Principles

### Beginner-First Approach
- Assume zero Rails knowledge
- Explain every concept and convention
- Show alternative approaches and why specific choices were made
- Make Rails "magic" explicit through detailed explanations

### Educational Value
- Working code first, then polish
- Test everything before moving forward
- Incremental complexity building
- Real-world professional practices

## Quick Start for Rails Development

If you're new to Rails or this project:

1. Start with [Project Setup & Initial Scaffolding](./rails8-docs/project-setup.md)
2. Review [MVC Architecture](./rails8-docs/mvc-architecture.md) 
3. Check out [New Rails 8 Features](./rails8-docs/rails8-new-features.md)
4. Follow our tutorial phases in `phase-*.md` files

## Contributing to Documentation

When extending this tutorial:
- Follow established documentation patterns
- Maintain beginner-friendly explanations
- Update relevant phase documents with new learnings
- Add troubleshooting notes for issues encountered
- Reference `rails8-docs/` for Rails 8 compliance
- Update journal entries with implementation details